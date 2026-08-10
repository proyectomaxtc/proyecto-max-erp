import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/access_denied_page.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../proveedores/models/proveedor_cuenta_model.dart';
import '../../proveedores/services/proveedor_service.dart';
import '../models/balance_gasto_model.dart';
import '../models/balance_mensual_model.dart';
import '../models/liquidacion_sueldo_model.dart';
import '../services/balance_service.dart';

class ReportesPage extends ConsumerStatefulWidget {
  const ReportesPage({super.key});

  @override
  ConsumerState<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends ConsumerState<ReportesPage> {
  final service = BalanceService();
  final proveedorService = ProveedorService();
  late Future<_ReportesData> reportesFuture;

  @override
  void initState() {
    super.initState();
    reportesFuture = _cargarData();
  }

  Future<_ReportesData> _cargarData() async {
    final balances = await service.obtenerBalancesMensuales();
    final gastos = await service.obtenerGastos();
    final liquidaciones = await service.obtenerLiquidaciones();
    final proveedores = await proveedorService.obtenerProveedores();
    final pagosProveedor = <_ProveedorPagoView>[];

    for (final proveedor in proveedores) {
      for (final movimiento in proveedor.movimientos) {
        if (movimiento.tipo == ProveedorMovimientoTipo.pago) {
          pagosProveedor.add(
            _ProveedorPagoView(proveedor: proveedor, movimiento: movimiento),
          );
        }
      }
    }

    pagosProveedor.sort(
      (a, b) => b.movimiento.fecha.compareTo(a.movimiento.fecha),
    );
    gastos.sort((a, b) => b.fecha.compareTo(a.fecha));
    liquidaciones.sort((a, b) => b.fechaPago.compareTo(a.fechaPago));

    return _ReportesData(
      balances: balances,
      gastos: gastos,
      liquidaciones: liquidaciones,
      pagosProveedor: pagosProveedor,
    );
  }

  void _recargar() {
    setState(() {
      reportesFuture = _cargarData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const AccessDeniedPage(
        title: 'Reportes',
        message:
            'Los reportes, balances y liquidaciones son solo para propietarios.',
      );
    }

    return MainLayout(
      title: 'Reportes',
      child: FutureBuilder<_ReportesData>(
        future: reportesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final balances = data.balances;
          final ahora = DateTime.now();
          final periodoActual = DateTime(ahora.year, ahora.month);
          final balancesMes = balances
              .where((balance) => _samePeriod(balance.periodo, periodoActual))
              .toList();
          final ventasMes = balancesMes.fold<double>(
            0,
            (total, balance) => total + balance.ventas,
          );
          final gastosMes = balancesMes.fold<double>(
            0,
            (total, balance) => total + balance.gastos + balance.sueldos,
          );
          final utilidadNetaMes = balancesMes.fold<double>(
            0,
            (total, balance) => total + balance.utilidadNeta,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                compact: compact,
                periodo: _periodLabel(periodoActual),
                ventas: ventasMes,
                egresos: gastosMes,
                utilidad: utilidadNetaMes,
              ),
              const SizedBox(height: 14),
              _ActionsBar(
                compact: compact,
                onGasto: () => _showGastoDialog(context),
                onSueldo: () => _showSueldoDialog(context),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    _MovimientosPanel(
                      gastos: data.gastos,
                      liquidaciones: data.liquidaciones,
                      pagosProveedor: data.pagosProveedor,
                      onEditarGasto: (gasto) =>
                          _showGastoDialog(context, gasto: gasto),
                      onEliminarGasto: _eliminarGasto,
                      onEditarSueldo: (liquidacion) =>
                          _showSueldoDialog(context, liquidacion: liquidacion),
                      onEliminarSueldo: _eliminarLiquidacion,
                    ),
                    const SizedBox(height: 14),
                    if (balances.isEmpty)
                      const _EmptyCard(
                        message:
                            'No hay balances para mostrar. Cargue ventas, compras, gastos o sueldos para iniciar el control mensual.',
                      )
                    else ...[
                      const Text(
                        'Balances mensuales por sucursal',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final balance in balances) ...[
                        _BalanceCard(balance: balance),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showGastoDialog(
    BuildContext context, {
    BalanceGastoModel? gasto,
  }) async {
    final result = await showDialog<BalanceGastoModel>(
      context: context,
      builder: (context) => _GastoDialog(gasto: gasto),
    );
    if (result == null) {
      return;
    }

    try {
      await service.guardarGasto(result);
      _recargar();
      _showSnack(gasto == null ? 'Gasto registrado' : 'Gasto actualizado');
    } catch (error) {
      _showSnack(error.toString(), error: true);
    }
  }

  Future<void> _showSueldoDialog(
    BuildContext context, {
    LiquidacionSueldoModel? liquidacion,
  }) async {
    final result = await showDialog<LiquidacionSueldoModel>(
      context: context,
      builder: (context) => _SueldoDialog(liquidacion: liquidacion),
    );
    if (result == null) {
      return;
    }

    try {
      await service.guardarLiquidacion(result);
      _recargar();
      _showSnack(
        liquidacion == null ? 'Liquidacion registrada' : 'Liquidacion actualizada',
      );
    } catch (error) {
      _showSnack(error.toString(), error: true);
    }
  }

  Future<void> _eliminarGasto(BalanceGastoModel gasto) async {
    final eliminar = await _confirmar(
      title: 'Eliminar gasto',
      message:
          'Desea eliminar "${gasto.concepto}" por ${CurrencyFormatter.format(gasto.monto)}?',
    );
    if (!eliminar) {
      return;
    }

    try {
      await service.eliminarGasto(gasto.id);
      _recargar();
      _showSnack('Gasto eliminado');
    } catch (error) {
      _showSnack(error.toString(), error: true);
    }
  }

  Future<void> _eliminarLiquidacion(LiquidacionSueldoModel liquidacion) async {
    final eliminar = await _confirmar(
      title: 'Eliminar sueldo',
      message:
          'Desea eliminar la liquidacion de ${liquidacion.empleado} por ${CurrencyFormatter.format(liquidacion.monto)}?',
    );
    if (!eliminar) {
      return;
    }

    try {
      await service.eliminarLiquidacion(liquidacion.id);
      _recargar();
      _showSnack('Liquidacion eliminada');
    } catch (error) {
      _showSnack(error.toString(), error: true);
    }
  }

  Future<bool> _confirmar({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  bool _samePeriod(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  String _periodLabel(DateTime date) {
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ReportesData {
  final List<BalanceMensualModel> balances;
  final List<BalanceGastoModel> gastos;
  final List<LiquidacionSueldoModel> liquidaciones;
  final List<_ProveedorPagoView> pagosProveedor;

  const _ReportesData({
    required this.balances,
    required this.gastos,
    required this.liquidaciones,
    required this.pagosProveedor,
  });
}

class _ProveedorPagoView {
  final ProveedorCuentaModel proveedor;
  final ProveedorMovimientoModel movimiento;

  const _ProveedorPagoView({
    required this.proveedor,
    required this.movimiento,
  });
}

class _SummaryRow extends StatelessWidget {
  final bool compact;
  final String periodo;
  final double ventas;
  final double egresos;
  final double utilidad;

  const _SummaryRow({
    required this.compact,
    required this.periodo,
    required this.ventas,
    required this.egresos,
    required this.utilidad,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        title: 'Ventas',
        value: CurrencyFormatter.format(ventas),
        icon: Icons.sell_outlined,
        color: AppColors.success,
        subtitle: periodo,
      ),
      KpiCard(
        title: 'Gastos + sueldos',
        value: CurrencyFormatter.format(egresos),
        icon: Icons.receipt_long_outlined,
        color: AppColors.warning,
        subtitle: 'Egresos operativos',
      ),
      KpiCard(
        title: 'Utilidad neta',
        value: CurrencyFormatter.format(utilidad),
        icon: Icons.trending_up,
        color: utilidad >= 0 ? AppColors.success : AppColors.error,
        subtitle: 'Despues de gastos',
      ),
    ];

    if (compact) {
      return SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) =>
              SizedBox(width: 164, child: cards[index]),
        ),
      );
    }

    return SizedBox(
      height: 132,
      child: Row(
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            Expanded(child: cards[index]),
            if (index < cards.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final bool compact;
  final VoidCallback onGasto;
  final VoidCallback onSueldo;

  const _ActionsBar({
    required this.compact,
    required this.onGasto,
    required this.onSueldo,
  });

  @override
  Widget build(BuildContext context) {
    final gasto = FilledButton.icon(
      onPressed: onGasto,
      icon: const Icon(Icons.add_card_outlined),
      label: const Text('Agregar gasto'),
    );
    final sueldo = OutlinedButton.icon(
      onPressed: onSueldo,
      icon: const Icon(Icons.payments_outlined),
      label: const Text('Liquidar sueldo'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [gasto, const SizedBox(height: 10), sueldo],
            )
          : Row(
              children: [
                const Expanded(
                  child: Text(
                    'Control mensual de gastos, sueldos y pagos',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                gasto,
                const SizedBox(width: 10),
                sueldo,
              ],
            ),
    );
  }
}

class _MovimientosPanel extends StatelessWidget {
  final List<BalanceGastoModel> gastos;
  final List<LiquidacionSueldoModel> liquidaciones;
  final List<_ProveedorPagoView> pagosProveedor;
  final ValueChanged<BalanceGastoModel> onEditarGasto;
  final ValueChanged<BalanceGastoModel> onEliminarGasto;
  final ValueChanged<LiquidacionSueldoModel> onEditarSueldo;
  final ValueChanged<LiquidacionSueldoModel> onEliminarSueldo;

  const _MovimientosPanel({
    required this.gastos,
    required this.liquidaciones,
    required this.pagosProveedor,
    required this.onEditarGasto,
    required this.onEliminarGasto,
    required this.onEditarSueldo,
    required this.onEliminarSueldo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movimientos registrados',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aca puede revisar y corregir gastos o sueldos. Los pagos a proveedores se muestran como control y no duplican compras de stock.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _MovimientoSection(
            title: 'Gastos del balance',
            icon: Icons.receipt_long_outlined,
            empty: 'No hay gastos cargados.',
            children: [
              for (final gasto in gastos)
                _GastoTile(
                  gasto: gasto,
                  onEdit: () => onEditarGasto(gasto),
                  onDelete: () => onEliminarGasto(gasto),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _MovimientoSection(
            title: 'Sueldos liquidados',
            icon: Icons.payments_outlined,
            empty: 'No hay sueldos cargados.',
            children: [
              for (final liquidacion in liquidaciones)
                _SueldoTile(
                  liquidacion: liquidacion,
                  onEdit: () => onEditarSueldo(liquidacion),
                  onDelete: () => onEliminarSueldo(liquidacion),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _MovimientoSection(
            title: 'Pagos a proveedores',
            icon: Icons.local_shipping_outlined,
            empty: 'No hay pagos a proveedores registrados.',
            children: [
              for (final pago in pagosProveedor) _ProveedorPagoTile(pago: pago),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovimientoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String empty;
  final List<Widget> children;

  const _MovimientoSection({
    required this.title,
    required this.icon,
    required this.empty,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (children.isEmpty)
            Text(empty, style: const TextStyle(color: AppColors.textSecondary))
          else
            Column(children: children),
        ],
      ),
    );
  }
}

class _GastoTile extends StatelessWidget {
  final BalanceGastoModel gasto;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GastoTile({
    required this.gasto,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _MovementTile(
      title: gasto.concepto,
      subtitle:
          '${gasto.categoria} - ${_sucursalLabel(gasto.sucursal)} - ${_date(gasto.fecha)}',
      amount: CurrencyFormatter.format(gasto.monto),
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _SueldoTile extends StatelessWidget {
  final LiquidacionSueldoModel liquidacion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SueldoTile({
    required this.liquidacion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _MovementTile(
      title: liquidacion.empleado,
      subtitle:
          '${_sucursalLabel(liquidacion.sucursal)} - Pago ${_date(liquidacion.fechaPago)} - Semana ${_date(liquidacion.periodoDesde)} a ${_date(liquidacion.periodoHasta)}',
      amount: CurrencyFormatter.format(liquidacion.monto),
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

class _ProveedorPagoTile extends StatelessWidget {
  final _ProveedorPagoView pago;

  const _ProveedorPagoTile({required this.pago});

  @override
  Widget build(BuildContext context) {
    final movimiento = pago.movimiento;
    return _MovementTile(
      title: pago.proveedor.nombre,
      subtitle:
          '${movimiento.concepto} - ${movimiento.medioPago} - ${_date(movimiento.fecha)}',
      amount: CurrencyFormatter.format(movimiento.monto),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MovementTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _content(context, compact: true),
            )
          : Row(children: _content(context, compact: false)),
    );
  }

  List<Widget> _content(BuildContext context, {required bool compact}) {
    final info = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar',
          ),
      ],
    );

    if (compact) {
      return [
        Row(children: [info]),
        const SizedBox(height: 8),
        actions,
      ];
    }

    return [info, const SizedBox(width: 12), actions];
  }
}

class _BalanceCard extends StatelessWidget {
  final BalanceMensualModel balance;

  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_periodLabel(balance.periodo)} - ${_sucursalLabel(balance.sucursal)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.format(balance.utilidadNeta),
                style: TextStyle(
                  color: balance.utilidadNeta >= 0
                      ? AppColors.success
                      : AppColors.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric('Ventas', balance.ventas),
              _Metric('Costo vendido', balance.costoVentas),
              _Metric('Utilidad bruta', balance.utilidadBruta),
              _Metric('Compras stock', balance.compras),
              _Metric('Gastos', balance.gastos),
              _Metric('Sueldos', balance.sueldos),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value;

  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          Text(
            CurrencyFormatter.format(value),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _GastoDialog extends StatefulWidget {
  final BalanceGastoModel? gasto;

  const _GastoDialog({this.gasto});

  @override
  State<_GastoDialog> createState() => _GastoDialogState();
}

class _GastoDialogState extends State<_GastoDialog> {
  final formKey = GlobalKey<FormState>();
  final conceptoController = TextEditingController();
  final montoController = TextEditingController();
  final observacionesController = TextEditingController();
  String sucursal = Branches.casaCentral;
  String categoria = 'Alquiler';
  String medioPago = 'Efectivo';
  DateTime fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    final gasto = widget.gasto;
    if (gasto != null) {
      sucursal = gasto.sucursal;
      categoria = gasto.categoria;
      medioPago = gasto.medioPago;
      fecha = gasto.fecha;
      conceptoController.text = gasto.concepto;
      montoController.text = gasto.monto.toStringAsFixed(0);
      observacionesController.text = gasto.observaciones;
    }
  }

  @override
  void dispose() {
    conceptoController.dispose();
    montoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.gasto != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(editando ? 'Editar gasto' : 'Agregar gasto al balance'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: sucursal,
                  decoration: _decoration('Aplicar a'),
                  dropdownColor: AppColors.surface,
                  items: Branches.balanceValues
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => sucursal = value ?? sucursal),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoria,
                  decoration: _decoration('Categoria'),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Alquiler',
                      child: Text('Alquiler'),
                    ),
                    DropdownMenuItem(
                      value: 'Servicios',
                      child: Text('Servicios'),
                    ),
                    DropdownMenuItem(
                      value: 'Transporte / envio',
                      child: Text('Transporte / envio'),
                    ),
                    DropdownMenuItem(
                      value: 'Impuestos',
                      child: Text('Impuestos'),
                    ),
                    DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                  ],
                  onChanged: (value) =>
                      setState(() => categoria = value ?? categoria),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: conceptoController,
                  label: 'Concepto',
                  required: true,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: montoController,
                  label: 'Monto',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _DateButton(
                  label: 'Fecha del gasto',
                  value: fecha,
                  onChanged: (value) => setState(() => fecha = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: medioPago,
                  decoration: _decoration('Medio de pago'),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(
                      value: 'Mercado Pago',
                      child: Text('Mercado Pago'),
                    ),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (value) =>
                      setState(() => medioPago = value ?? medioPago),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: observacionesController,
                  label: 'Observaciones',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }
            final now = DateTime.now();
            final id = widget.gasto?.id ?? now.microsecondsSinceEpoch.toString();
            Navigator.pop(
              context,
              BalanceGastoModel(
                id: id,
                sucursal: sucursal,
                categoria: categoria,
                concepto: conceptoController.text.trim(),
                monto: _parseNumber(montoController.text),
                medioPago: medioPago,
                fecha: fecha,
                observaciones: observacionesController.text.trim(),
              ),
            );
          },
          child: Text(editando ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _SueldoDialog extends StatefulWidget {
  final LiquidacionSueldoModel? liquidacion;

  const _SueldoDialog({this.liquidacion});

  @override
  State<_SueldoDialog> createState() => _SueldoDialogState();
}

class _SueldoDialogState extends State<_SueldoDialog> {
  final formKey = GlobalKey<FormState>();
  final empleadoController = TextEditingController();
  final montoController = TextEditingController();
  final observacionesController = TextEditingController();
  String sucursal = Branches.alberdi;
  String medioPago = 'Efectivo';
  DateTime desde = DateTime.now().subtract(const Duration(days: 6));
  DateTime hasta = DateTime.now();
  DateTime pago = DateTime.now();

  @override
  void initState() {
    super.initState();
    final liquidacion = widget.liquidacion;
    if (liquidacion != null) {
      sucursal = liquidacion.sucursal;
      medioPago = liquidacion.medioPago;
      desde = liquidacion.periodoDesde;
      hasta = liquidacion.periodoHasta;
      pago = liquidacion.fechaPago;
      empleadoController.text = liquidacion.empleado;
      montoController.text = liquidacion.monto.toStringAsFixed(0);
      observacionesController.text = liquidacion.observaciones;
    }
  }

  @override
  void dispose() {
    empleadoController.dispose();
    montoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.liquidacion != null;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(editando ? 'Editar liquidacion' : 'Liquidacion semanal'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: sucursal,
                  decoration: _decoration('Sucursal'),
                  dropdownColor: AppColors.surface,
                  items: Branches.values
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => sucursal = value ?? sucursal),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: empleadoController,
                  label: 'Empleado',
                  required: true,
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: montoController,
                  label: 'Monto abonado',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                _DateRow(
                  desde: desde,
                  hasta: hasta,
                  pago: pago,
                  onDesde: (value) => setState(() => desde = value),
                  onHasta: (value) => setState(() => hasta = value),
                  onPago: (value) => setState(() => pago = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: medioPago,
                  decoration: _decoration('Medio de pago'),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Efectivo',
                      child: Text('Efectivo'),
                    ),
                    DropdownMenuItem(
                      value: 'Transferencia',
                      child: Text('Transferencia'),
                    ),
                    DropdownMenuItem(
                      value: 'Mercado Pago',
                      child: Text('Mercado Pago'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => medioPago = value ?? medioPago),
                ),
                const SizedBox(height: 12),
                _DialogField(
                  controller: observacionesController,
                  label: 'Observaciones',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!formKey.currentState!.validate()) {
              return;
            }
            final id = widget.liquidacion?.id ??
                DateTime.now().microsecondsSinceEpoch.toString();
            Navigator.pop(
              context,
              LiquidacionSueldoModel(
                id: id,
                empleado: empleadoController.text.trim(),
                sucursal: sucursal,
                monto: _parseNumber(montoController.text),
                periodoDesde: desde,
                periodoHasta: hasta,
                fechaPago: pago,
                medioPago: medioPago,
                observaciones: observacionesController.text.trim(),
              ),
            );
          },
          child: Text(editando ? 'Actualizar' : 'Guardar'),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime desde;
  final DateTime hasta;
  final DateTime pago;
  final ValueChanged<DateTime> onDesde;
  final ValueChanged<DateTime> onHasta;
  final ValueChanged<DateTime> onPago;

  const _DateRow({
    required this.desde,
    required this.hasta,
    required this.pago,
    required this.onDesde,
    required this.onHasta,
    required this.onPago,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateButton(label: 'Desde', value: desde, onChanged: onDesde),
        const SizedBox(height: 8),
        _DateButton(label: 'Hasta', value: hasta, onChanged: onHasta),
        const SizedBox(height: 8),
        _DateButton(label: 'Fecha de pago', value: pago, onChanged: onPago),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text('$label: ${_date(value)}'),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Campo obligatorio'
                : null
          : null,
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

double _parseNumber(String value) {
  final normalizado = value.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalizado) ?? 0;
}

String _date(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _periodLabel(DateTime date) {
  final months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _sucursalLabel(String sucursal) {
  if (sucursal == Branches.casaCentral) {
    return 'Santa Fe';
  }
  if (sucursal == Branches.alberdi) {
    return 'Alberdi';
  }
  return 'Ambas sucursales';
}
