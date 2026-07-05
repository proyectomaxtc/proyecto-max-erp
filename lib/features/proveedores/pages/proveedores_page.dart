import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/cards/kpi_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/proveedor_cuenta_model.dart';
import '../providers/proveedor_provider.dart';

class ProveedoresPage extends ConsumerStatefulWidget {
  const ProveedoresPage({super.key});

  @override
  ConsumerState<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends ConsumerState<ProveedoresPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(proveedorProvider.notifier).cargarProveedores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final esPropietario = ref.watch(authProvider).esPropietario;
    final state = ref.watch(proveedorProvider);
    final compact = MediaQuery.sizeOf(context).width < 760;

    if (!esPropietario) {
      return const MainLayout(
        title: 'Proveedores',
        child: Center(
          child: Text(
            'Solo el propietario puede administrar proveedores.',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return MainLayout(
      title: 'Proveedores',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Summary(compact: compact),
          const SizedBox(height: 14),
          _Toolbar(compact: compact),
          const SizedBox(height: 14),
          Expanded(
            child: state.filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay proveedores para mostrar.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: state.filtrados.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _ProveedorCard(proveedor: state.filtrados[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends ConsumerWidget {
  final bool compact;

  const _Summary({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proveedorProvider);
    final cards = [
      KpiCard(
        title: 'Deuda total',
        value: CurrencyFormatter.format(state.deudaTotal),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.error,
        subtitle: 'Cuenta corriente',
      ),
      KpiCard(
        title: 'Proveedores',
        value: state.proveedores.length.toString(),
        icon: Icons.local_shipping_outlined,
        color: AppColors.primary,
        subtitle: 'Cargados',
      ),
      KpiCard(
        title: 'Con deuda',
        value: state.conDeuda.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        subtitle: 'Pendientes de pago',
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
              SizedBox(width: 160, child: cards[index]),
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

class _Toolbar extends ConsumerWidget {
  final bool compact;

  const _Toolbar({required this.compact});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = TextField(
      onChanged: (value) => ref.read(proveedorProvider.notifier).buscar(value),
      decoration: InputDecoration(
        hintText: 'Buscar proveedor...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final button = FilledButton.icon(
      onPressed: () => _showProveedorDialog(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Nuevo proveedor'),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 10), button],
            )
          : Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                button,
              ],
            ),
    );
  }

  Future<void> _showProveedorDialog(BuildContext context, WidgetRef ref) async {
    final proveedor = await showDialog<ProveedorCuentaModel>(
      context: context,
      builder: (context) => const _ProveedorDialog(),
    );
    if (proveedor == null) {
      return;
    }

    await ref.read(proveedorProvider.notifier).guardarProveedor(proveedor);
  }
}

class _ProveedorCard extends ConsumerWidget {
  final ProveedorCuentaModel proveedor;

  const _ProveedorCard({required this.proveedor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proveedor.nombre,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (proveedor.telefono.trim().isNotEmpty)
                      Text(
                        proveedor.telefono,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(proveedor.deudaTotal),
                style: TextStyle(
                  color: proveedor.deudaTotal > 0
                      ? AppColors.error
                      : AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _showMovimientoDialog(
                  context,
                  ref,
                  ProveedorMovimientoTipo.deuda,
                ),
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Agregar deuda'),
              ),
              OutlinedButton.icon(
                onPressed: proveedor.deudaTotal <= 0
                    ? null
                    : () => _showMovimientoDialog(
                        context,
                        ref,
                        ProveedorMovimientoTipo.pago,
                      ),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Registrar pago'),
              ),
            ],
          ),
          if (proveedor.movimientos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...proveedor.movimientos
                .take(3)
                .map((movimiento) => _MovimientoRow(movimiento: movimiento)),
          ],
        ],
      ),
    );
  }

  Future<void> _showMovimientoDialog(
    BuildContext context,
    WidgetRef ref,
    String tipo,
  ) async {
    final movimiento = await showDialog<ProveedorMovimientoModel>(
      context: context,
      builder: (context) => _MovimientoDialog(tipo: tipo),
    );
    if (movimiento == null) {
      return;
    }

    await ref
        .read(proveedorProvider.notifier)
        .agregarMovimiento(proveedorId: proveedor.id, movimiento: movimiento);
  }
}

class _MovimientoRow extends StatelessWidget {
  final ProveedorMovimientoModel movimiento;

  const _MovimientoRow({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final esPago = movimiento.tipo == ProveedorMovimientoTipo.pago;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            esPago ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 18,
            color: esPago ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              movimiento.concepto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            CurrencyFormatter.format(movimiento.monto),
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

class _ProveedorDialog extends StatefulWidget {
  const _ProveedorDialog();

  @override
  State<_ProveedorDialog> createState() => _ProveedorDialogState();
}

class _ProveedorDialogState extends State<_ProveedorDialog> {
  final formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final observacionesController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Nuevo proveedor'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                controller: nombreController,
                label: 'Proveedor',
                required: true,
              ),
              const SizedBox(height: 12),
              _DialogField(controller: telefonoController, label: 'Telefono'),
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
              ProveedorCuentaModel(
                id: now.microsecondsSinceEpoch.toString(),
                nombre: nombreController.text.trim(),
                telefono: telefonoController.text.trim(),
                observaciones: observacionesController.text.trim(),
                creado: now,
                actualizado: now,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _MovimientoDialog extends StatefulWidget {
  final String tipo;

  const _MovimientoDialog({required this.tipo});

  @override
  State<_MovimientoDialog> createState() => _MovimientoDialogState();
}

class _MovimientoDialogState extends State<_MovimientoDialog> {
  final formKey = GlobalKey<FormState>();
  final conceptoController = TextEditingController();
  final montoController = TextEditingController();
  final responsableController = TextEditingController();
  final observacionesController = TextEditingController();
  String medioPago = 'Efectivo';

  @override
  void initState() {
    super.initState();
    conceptoController.text = widget.tipo == ProveedorMovimientoTipo.pago
        ? 'Pago a proveedor'
        : 'Compra / deuda pendiente';
  }

  @override
  void dispose() {
    conceptoController.dispose();
    montoController.dispose();
    responsableController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esPago = widget.tipo == ProveedorMovimientoTipo.pago;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(esPago ? 'Registrar pago' : 'Agregar deuda'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                dropdownColor: AppColors.surface,
                decoration: _inputDecoration('Medio de pago'),
                items: const [
                  DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                  DropdownMenuItem(
                    value: 'Transferencia',
                    child: Text('Transferencia'),
                  ),
                  DropdownMenuItem(
                    value: 'Mercado Pago',
                    child: Text('Mercado Pago'),
                  ),
                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  medioPago = value ?? medioPago;
                },
              ),
              const SizedBox(height: 12),
              _DialogField(
                controller: responsableController,
                label: 'Responsable',
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
              ProveedorMovimientoModel(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                tipo: widget.tipo,
                concepto: conceptoController.text.trim(),
                monto: _parseNumber(montoController.text),
                medioPago: medioPago,
                fecha: DateTime.now(),
                responsable: responsableController.text.trim(),
                observaciones: observacionesController.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  double _parseNumber(String value) {
    final normalizado = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
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
      decoration: _inputDecoration(label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Campo obligatorio'
                : null
          : null,
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.card,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
