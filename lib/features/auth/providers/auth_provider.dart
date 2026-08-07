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
  static const _sessionSavedAtKey = 'auth_session_saved_at';
  static const _employeeSessionTtl = Duration(hours: 14);

  AuthNotifier(this.service) : super(const AuthState()) {
    _iniciarSesion();
  }

  Future<void> _iniciarSesion() async {
    await _restaurarSesionTemporal();
    await cargarUsuarios();
  }

  Future<void> cargarUsuarios() async {
    try {
      final usuarios = await service.obtenerUsuarios();
      final usuarioActual = state.usuario;
      final usuarioVigente = usuarioActual != null &&
              usuarios.any(
                (usuario) => usuario.id == usuarioActual.id && usuario.activo,
              )
          ? usuarioActual
          : null;

      if (usuarioActual != null && usuarioVigente == null) {
        await _limpiarSesion();
        await SupabaseAuthService.signOut();
      }

      state = state.copyWith(
        usuarios: usuarios,
        usuario: usuarioVigente,
        limpiarUsuario: usuarioVigente == null,
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
      final localOk = await _loginEmailLocal(
        emailNormalizado: nombreNormalizado,
        codigoNormalizado: codigoNormalizado,
      );
      if (localOk) {
        return true;
      }

      final error =
          signIn.error ?? 'Email o contrasena de Supabase incorrectos.';
      state = state.copyWith(
        error:
            '$error Tambien puede ingresar con el mismo email y el codigo local si ese usuario ya esta cargado en la app.',
        cargandoSesion: false,
      );
      return false;
    }

    final usuarios = await service.obtenerUsuarios();
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

    if (cloudUser == null) {
      state = state.copyWith(
        usuarios: usuarios,
        error:
            'El email inicio sesion en Supabase, pero falta asociarlo en user_profiles.',
        cargandoSesion: false,
      );
      return false;
    }

    final usuarioFinal = _conservarDatosLocales(cloudUser, usuarios);

    await service.guardarUsuario(usuarioFinal);
    final usuariosActualizados = await service.obtenerUsuarios();
    state = state.copyWith(
      usuario: usuarioFinal,
      usuarios: usuariosActualizados,
      limpiarError: true,
      cargandoSesion: false,
    );
    await _guardarSesion(usuarioFinal);
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

  Future<bool> _loginEmailLocal({
    required String emailNormalizado,
    required String codigoNormalizado,
  }) async {
    final usuarios = await service.obtenerUsuarios();

    for (final usuario in usuarios) {
      final emailUsuario = usuario.email.trim().toLowerCase();
      final codigoUsuario = usuario.codigo.trim();
      if (usuario.activo &&
          emailUsuario == emailNormalizado &&
          codigoUsuario.isNotEmpty &&
          codigoUsuario == codigoNormalizado) {
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
    if (usuario.esPropietario) {
      await _limpiarSesion();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionUserIdKey, usuario.id);
    await prefs.setString(_sessionUserProfileKey, jsonEncode(usuario.toMap()));
    await prefs.setString(
      _sessionSavedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _restaurarSesionTemporal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_sessionUserProfileKey);
    final rawSavedAt = prefs.getString(_sessionSavedAtKey);
    if (rawProfile == null || rawProfile.trim().isEmpty) {
      return;
    }

    final savedAt = DateTime.tryParse(rawSavedAt ?? '');
    if (savedAt == null ||
        DateTime.now().difference(savedAt) > _employeeSessionTtl) {
      await _limpiarSesion();
      return;
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is! Map) {
        await _limpiarSesion();
        return;
      }

      final usuario = AppUserModel.fromMap(decoded);
      if (!usuario.activo || usuario.esPropietario) {
        await _limpiarSesion();
        return;
      }

      state = state.copyWith(usuario: usuario, cargandoSesion: false);
    } catch (_) {
      await _limpiarSesion();
    }
  }

  AppUserModel _conservarDatosLocales(
    AppUserModel cloudUser,
    List<AppUserModel> usuarios,
  ) {
    for (final usuario in usuarios) {
      final mismoId = usuario.id == cloudUser.id;
      final mismoAuth =
          usuario.authId.isNotEmpty && usuario.authId == cloudUser.authId;
      final mismoEmail =
          usuario.email.trim().toLowerCase().isNotEmpty &&
          usuario.email.trim().toLowerCase() ==
              cloudUser.email.trim().toLowerCase();

      if (mismoId || mismoAuth || mismoEmail) {
        return cloudUser.copyWith(
          codigo: cloudUser.codigo.isEmpty ? usuario.codigo : cloudUser.codigo,
          creado: usuario.creado,
        );
      }
    }

    return cloudUser;
  }

  Future<void> _limpiarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionUserIdKey);
    await prefs.remove(_sessionUserProfileKey);
    await prefs.remove(_sessionSavedAtKey);
  }
}
