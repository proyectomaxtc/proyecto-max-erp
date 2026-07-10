import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/supabase_auth_service.dart';
import '../models/app_user_model.dart';
import '../services/user_service.dart';
import '../state/auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(UserService()),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final UserService service;
  static const _sessionUserIdKey = 'auth_session_user_id';
  static const _sessionUserProfileKey = 'auth_session_user_profile';

  AuthNotifier(this.service) : super(const AuthState()) {
    cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    try {
      final usuarios = await service.obtenerUsuarios();
      final usuarioActual = state.usuario;
      final usuarioRestaurado =
          usuarioActual ??
          await _restaurarUsuario(usuarios) ??
          await _restaurarPerfilGuardado() ??
          await _restaurarUsuarioSupabase(usuarios);
      if (usuarioRestaurado != null) {
        await _guardarSesion(usuarioRestaurado);
      }

      state = state.copyWith(
        usuarios: usuarios,
        usuario: usuarioRestaurado,
        cargandoSesion: false,
      );
    } catch (_) {
      state = state.copyWith(cargandoSesion: false);
    }
  }

  Future<bool> esPropietarioActual() async {
    if (state.usuario?.esPropietario == true) {
      return true;
    }

    await cargarUsuarios();
    return state.usuario?.esPropietario == true;
  }

  Future<bool> login({required String nombre, required String codigo}) async {
    final nombreNormalizado = nombre.trim().toLowerCase();
    final codigoNormalizado = codigo.trim();
    final onlineLogin = nombreNormalizado.contains('@');

    if (!onlineLogin) {
      return _loginLocal(
        nombreNormalizado: nombreNormalizado,
        codigoNormalizado: codigoNormalizado,
      );
    }

    final signIn = await SupabaseAuthService.signIn(
      identifier: nombre,
      password: codigo,
    );
    final authId = signIn.authId;

    if (authId == null) {
      state = state.copyWith(
        error:
            signIn.error ??
            'Email o contrasena de Supabase incorrectos. Use la contrasena creada en Supabase.',
        cargandoSesion: false,
      );
      return false;
    }

    final cloudProfile = await SupabaseAuthService.loadProfile(
      identifier: nombre,
      authId: authId,
    );
    final usuarios = await service.obtenerUsuarios();
    final cloudUser =
        cloudProfile ??
        SupabaseAuthService.matchUser(
          users: usuarios,
          identifier: nombre,
          authId: authId,
        );

    if (cloudUser == null) {
      state = state.copyWith(
        usuarios: usuarios,
        error:
            'El email inicio sesion en Supabase, pero falta asociarlo en user_profiles.',
        cargandoSesion: false,
      );
      return false;
    }

    await service.guardarUsuario(cloudUser);
    final usuariosActualizados = await service.obtenerUsuarios();
    state = state.copyWith(
      usuario: cloudUser,
      usuarios: usuariosActualizados,
      limpiarError: true,
      cargandoSesion: false,
    );
    await _guardarSesion(cloudUser);
    return true;
  }

  Future<bool> _loginLocal({
    required String nombreNormalizado,
    required String codigoNormalizado,
  }) async {
    final usuarios = await service.obtenerUsuarios();

    for (final usuario in usuarios) {
      if (usuario.activo &&
          usuario.nombre.trim().toLowerCase() == nombreNormalizado &&
          usuario.codigo == codigoNormalizado) {
        state = state.copyWith(
          usuario: usuario,
          usuarios: usuarios,
          limpiarError: true,
          cargandoSesion: false,
        );
        await _guardarSesion(usuario);
        return true;
      }
    }

    state = state.copyWith(
      usuarios: usuarios,
      error: 'Nombre o codigo incorrecto',
      cargandoSesion: false,
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
    if (usuarioActualizado?.id == usuario.id) {
      await _guardarSesion(usuario);
    }

    final actualizados = await service.obtenerUsuarios();
    state = state.copyWith(
      usuario: usuarioActualizado,
      usuarios: actualizados,
      limpiarError: true,
    );
  }

  void logout() {
    SupabaseAuthService.signOut();
    _limpiarSesion();
    state = state.copyWith(limpiarUsuario: true, cargandoSesion: false);
  }

  Future<void> _guardarSesion(AppUserModel usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, usuario.id);
    await prefs.setString(_sessionUserProfileKey, jsonEncode(usuario.toMap()));
  }

  Future<AppUserModel?> _restaurarUsuario(List<AppUserModel> usuarios) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_sessionUserIdKey);
    if (userId == null || userId.isEmpty) {
      return null;
    }

    for (final usuario in usuarios) {
      if (usuario.id == userId && usuario.activo) {
        return usuario;
      }
    }

    await prefs.remove(_sessionUserIdKey);
    return null;
  }

  Future<AppUserModel?> _restaurarPerfilGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_sessionUserProfileKey);
    if (rawProfile == null || rawProfile.isEmpty) {
      return null;
    }

    try {
      final data = jsonDecode(rawProfile);
      if (data is! Map) {
        return null;
      }

      final usuario = AppUserModel.fromMap(data);
      if (!usuario.activo || usuario.id.isEmpty) {
        return null;
      }

      return usuario;
    } catch (_) {
      await prefs.remove(_sessionUserProfileKey);
      return null;
    }
  }

  Future<AppUserModel?> _restaurarUsuarioSupabase(
    List<AppUserModel> usuarios,
  ) async {
    final authId = SupabaseAuthService.currentAuthId();
    final email = SupabaseAuthService.currentEmail();
    if (authId == null || email == null) {
      return null;
    }

    final cloudUser =
        SupabaseAuthService.matchUser(
          users: usuarios,
          identifier: email,
          authId: authId,
        ) ??
        await SupabaseAuthService.loadProfile(
          identifier: email,
          authId: authId,
        );

    if (cloudUser == null) {
      return null;
    }

    await service.guardarUsuario(cloudUser);
    await _guardarSesion(cloudUser);
    return cloudUser;
  }

  Future<void> _limpiarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_sessionUserProfileKey);
  }
}
