import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/branches.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../caja/models/caja_movimiento_model.dart';
import '../../caja/providers/caja_provider.dart';
import '../../clientes/models/cliente_model.dart';
import '../../clientes/providers/cliente_provider.dart';
import '../../notificaciones/providers/notification_provider.dart';
import '../models/servicio_model.dart';
import '../providers/servicio_provider.dart';

class ServicioForm extends ConsumerStatefulWidget {
  const ServicioForm({super.key});

  @override
  ConsumerState<ServicioForm> createState() => _ServicioFormState();
}

class _ServicioFormState extends ConsumerState<ServicioForm> {
  final _formKey = GlobalKey<FormState>();
  final descripcionController = TextEditingController();
  final tecnicoController = TextEditingController();
  final manoObraController = TextEditingController(text: '0');
  final repuestosController = TextEditingController(text: '0');
  final observacionesController = TextEditingController();

  ClienteModel? clienteSeleccionado;
  String estado = 'Pendiente';
  String medioPago = 'Efectivo';
  bool cobrado = false;

  double get manoObra => double.tryParse(manoObraController.text) ?? 0;
  double get repuestos => double.tryParse(repuestosController.text) ?? 0;
  double get total => manoObra + repuestos;

  @override
  void initState() {
    super.initState();
    manoObraController.addListener(_refresh);
    repuestosController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    descripcionController.dispose();
    tecnicoController.dispose();
    manoObraController.dispose();
    repuestosController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> guardarServicio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (clienteSeleccionado == null) {
      _error('Seleccione un cliente');
      return;
    }

    final usuario = ref.read(authProvider).usuario;
    final sucursal = usuario?.sucursal ?? Branches.casaCentral;
    final turno = ref.read(cajaProvider).turnoAbiertoParaSucursal(sucursal);

    if (cobrado && turno == null) {
      _error('Debe abrir caja de $sucursal antes de cobrar un servicio');
      return;
    }

    final ahora = DateTime.now();
    final numero = await ref
        .read(servicioProvider.notifier)
        .generarNumeroServicio();
    final cliente = clienteSeleccionado!;

    final servicio = ServicioModel(
      id: ahora.microsecondsSinceEpoch.toString(),
      numero: numero,
      clienteId: cliente.id,
      clienteNombre: '${cliente.nombre} ${cliente.apellido}'.trim(),
      sucursal: sucursal,
      descripcion: descripcionController.text.trim(),
      tecnico: tecnicoController.text.trim(),
      estado: estado,
      manoObra: manoObra,
      repuestos: repuestos,
      total: total,
      cobrado: cobrado,
      medioPago: medioPago,
      creado: ahora,
      entregado: estado == 'Entregado' ? ahora : null,
      observaciones: observacionesController.text.trim(),
    );

    await ref.read(servicioProvider.notifier).agregarServicio(servicio);

    if (cobrado && turno != null) {
      await ref
          .read(cajaProvider.notifier)
          .agregarMovimiento(
            CajaMovimientoModel(
              id: '${servicio.id}-caja',
              tipo: 'Ingreso',
              concepto:
                  'Servicio ${servicio.numero} - ${servicio.clienteNombre}',
              monto: servicio.total,
              medioPago: servicio.medioPago,
              referenciaId: servicio.id,
              origen: 'Servicio',
              turnoId: turno.id,
              responsable: turno.responsable,
              bloqueado: true,
              fecha: servicio.creado,
              observaciones: servicio.observaciones,
            ),
          );
    }

    await ref
        .read(notificationProvider.notifier)
        .registrar(
          usuario: usuario,
          tipo: 'Servicio',
          titulo: 'Servicio ${servicio.numero}',
          detalle:
              '${servicio.clienteNombre} - ${CurrencyFormatter.format(servicio.total)} - $estado',
          ruta: AppRoutes.servicios,
          monto: servicio.total,
        );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Servicio registrado correctamente'),
      ),
    );
  }

  void _error(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref
        .watch(clienteProvider)
        .clientes
        .where((cliente) => cliente.activo)
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClienteModel>(
                  initialValue: clienteSeleccionado,
                  decoration: decoration("Cliente"),
                  dropdownColor: AppColors.surface,
                  items: clientes
                      .map(
                        (cliente) => DropdownMenuItem(
                          value: cliente,
                          child: Text(
                            '${cliente.nombre} ${cliente.apellido}'.trim(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (cliente) {
                    setState(() => clienteSeleccionado = cliente);
                  },
                  validator: (value) =>
                      value == null ? "Seleccione cliente" : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: tecnicoController,
                  decoration: decoration("Tecnico / responsable"),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? "Ingrese responsable"
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: descripcionController,
            maxLines: 3,
            decoration: decoration("Trabajo a realizar"),
            validator: (value) => value == null || value.trim().isEmpty
                ? "Ingrese descripcion"
                : null,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: estado,
                  decoration: decoration("Estado"),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(
                      value: 'Pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'En proceso',
                      child: Text('En proceso'),
                    ),
                    DropdownMenuItem(value: 'Listo', child: Text('Listo')),
                    DropdownMenuItem(
                      value: 'Entregado',
                      child: Text('Entregado'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => estado = value ?? estado),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: manoObraController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration("Mano de obra"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: repuestosController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: decoration("Repuestos"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  value: cobrado,
                  title: const Text("Cobrado"),
                  onChanged: (value) => setState(() => cobrado = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: medioPago,
                  decoration: decoration("Medio de pago"),
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
                    DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                    DropdownMenuItem(
                      value: 'Cuenta corriente',
                      child: Text('Cuenta corriente'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => medioPago = value ?? medioPago),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: observacionesController,
            maxLines: 3,
            decoration: decoration("Observaciones"),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total: \$ ${total.toStringAsFixed(0)}",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: guardarServicio,
                icon: const Icon(Icons.save_outlined),
                label: const Text("Guardar Servicio"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
