import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_auth_service.dart';
import '../models/app_user_model.dart';
import '../services/user_service.dart';
import '../state/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(UserService()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final UserService service;

  AuthNotifier(this.service) : super(const AuthState()) {
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    final usuarios = await service.obtenerUsuarios();
    state = state.copyWith(usuarios: usuarios);
  }

  Future<bool> login({required String nombre, required String codigo}) async {
    var usuarios = await service.obtenerUsuarios();
    final nombreNormalizado = nombre.trim().toLowerCase();
    final codigoNormalizado = codigo.trim();
    final authId = await SupabaseAuthService.signIn(
      identifier: nombre,
      password: codigo,
    );

    if (authId != null) {
      usuarios = await service.obtenerUsuarios();
      final cloudUser =
          SupabaseAuthService.matchUser(
            users: usuarios,
            identifier: nombre,
            authId: authId,
          ) ??
          await SupabaseAuthService.loadProfile(
            identifier: nombre,
            authId: authId,
          );

      if (cloudUser != null) {
        await service.guardarUsuario(cloudUser);
        state = state.copyWith(
          usuario: cloudUser,
          usuarios: await service.obtenerUsuarios(),
          limpiarError: true,
        );
        return true;
      }
    }

    for (final usuario in usuarios) {
      if (usuario.activo &&
          usuario.nombre.trim().toLowerCase() == nombreNormalizado &&
          usuario.codigo == codigoNormalizado) {
        state = state.copyWith(
          usuario: usuario,
          usuarios: usuarios,
          limpiarError: true,
        );
        return true;
      }
    }

    state = state.copyWith(
      usuarios: usuarios,
      error: 'Nombre o codigo incorrecto',
    );
    return false;
  }

  Future<void> agregarUsuario(AppUserModel usuario) async {
    await service.guardarUsuario(usuario);
    await cargarUsuarios();
  }

  Future<void> actualizarUsuario(AppUserModel usuario) async {
    final usuarios = await service.obtenerUsuarios();
    final activosPropietarios = usuarios
        .where(
          (item) => item.id != usuario.id && item.activo && item.esPropietario,
        )
        .length;

    if ((!usuario.activo || !usuario.esPropietario) &&
        activosPropietarios == 0) {
      state = state.copyWith(
        usuarios: usuarios,
        error: 'Debe quedar al menos un propietario activo',
      );
      return;
    }

    await service.guardarUsuario(usuario);

    final usuarioActualizado = state.usuario?.id == usuario.id
        ? usuario
        : state.usuario;

    final actualizados = await service.obtenerUsuarios();
    state = state.copyWith(
      usuario: usuarioActualizado,
      usuarios: actualizados,
      limpiarError: true,
    );
  }

  void logout() {
    SupabaseAuthService.signOut();
    state = state.copyWith(limpiarUsuario: true);
  }
}
