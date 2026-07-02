import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';

class ClienteController extends ChangeNotifier {
  final List<ClienteModel> _clientes = [
    ClienteModel(
      id: '1',
      nombre: 'Juan',
      apellido: 'Pérez',
      telefono: '381555123',
      email: 'juan@email.com',
      direccion: 'San Martín 123',
      ciudad: 'San Miguel de Tucumán',
      provincia: 'Tucumán',
      cuit: '20-12345678-9',
      observaciones: 'Cliente de prueba',
      activo: true,
      creado: DateTime.now(),
      actualizado: DateTime.now(),
    ),
  ];

  List<ClienteModel> get clientes => List.unmodifiable(_clientes);

  void agregar(ClienteModel cliente) {
    _clientes.add(cliente);
    notifyListeners();
  }

  void editar(ClienteModel cliente) {
    final index = _clientes.indexWhere((c) => c.id == cliente.id);

    if (index != -1) {
      _clientes[index] = cliente.copyWith(
        actualizado: DateTime.now(),
      );

      notifyListeners();
    }
  }

  void eliminar(String id) {
    _clientes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  ClienteModel? obtenerPorId(String id) {
    try {
      return _clientes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}