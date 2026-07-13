import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/access_denied_page.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
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
  late Future<List<BalanceMensualModel>> balancesFuture;

  @override
  void initState() {
    super.initState();
    balancesFuture = service.obtenerBalancesMensuales();
  }

  void _recargar() {
    setState(() {
      balancesFuture = service.obtenerBalancesMensuales();
    });
  }

  @override
  Widget build(BuildContext context) {
    final esPropietario = ref.watch(authProvider).esPropietario;
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const AccessDeniedPage(
        title: "Reportes",
        message: "Los reportes, balances y liquidaciones son solo para propietarios.",
      );
    }

    return MainLayout(
      title: 'Reportes',
      child: FutureBuilder<List<BalanceMensualModel>>(
        future: balancesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final balances = snapshot.data!;
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
                child: balances.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay balances para mostrar.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        itemCount: balances.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _BalanceCard(balance: balances[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showGastoDialog(BuildContext context) async {
    final gasto = await showDialog<BalanceGastoModel>(
      context: context,
      builder: (context) => const _GastoDialog(),
    );
    if (gasto == null) {
      return;
    }

    await service.guardarGasto(gasto);
    _recargar();
  }

  Future<void> _showSueldoDialog(BuildContext context) async {
    final liquidacion = await showDialog<LiquidacionSueldoModel>(
      context: context,
      builder: (context) => const _SueldoDialog(),
    );
    if (liquidacion == null) {
      return;
    }

    await service.guardarLiquidacion(liquidacion);
    _recargar();
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
                    'Balances mensuales por sucursal',
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
    return sucursal == Branches.casaCentral ? 'Santa Fe' : 'Alberdi';
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

class _GastoDialog extends StatefulWidget {
  const _GastoDialog();

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

  @override
  void dispose() {
    conceptoController.dispose();
    montoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Agregar gasto al balance'),
      content: SizedBox(
        width: 480,
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
                  onChanged: (value) => sucursal = value ?? sucursal,
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
                  onChanged: (value) => categoria = value ?? categoria,
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
                  onChanged: (value) => medioPago = value ?? medioPago,
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
            Navigator.pop(
              context,
              BalanceGastoModel(
                id: now.microsecondsSinceEpoch.toString(),
                sucursal: sucursal,
                categoria: categoria,
                concepto: conceptoController.text.trim(),
                monto: _parseNumber(montoController.text),
                medioPago: medioPago,
                fecha: now,
                observaciones: observacionesController.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _SueldoDialog extends StatefulWidget {
  const _SueldoDialog();

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
  void dispose() {
    empleadoController.dispose();
    montoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Liquidacion semanal'),
      content: SizedBox(
        width: 480,
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
                  onChanged: (value) => sucursal = value ?? sucursal,
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
                  onChanged: (value) => medioPago = value ?? medioPago,
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
            Navigator.pop(
              context,
              LiquidacionSueldoModel(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
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
          child: const Text('Guardar'),
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

  String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
