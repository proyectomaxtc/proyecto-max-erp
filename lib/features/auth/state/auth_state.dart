import '../models/app_user_model.dart';

class AuthState {
  final AppUserModel? usuario;
  final List<AppUserModel> usuarios;
  final String? error;
  final bool cargandoSesion;

  const AuthState({
    this.usuario,
    this.usuarios = const [],
    this.error,
    this.cargandoSesion = true,
  });

  bool get autenticado => usuario != null;

  bool get esPropietario => usuario?.esPropietario ?? false;

  AuthState copyWith({
    AppUserModel? usuario,
    List<AppUserModel>? usuarios,
    String? error,
    bool? cargandoSesion,
    bool limpiarUsuario = false,
    bool limpiarError = false,
  }) {
    return AuthState(
      usuario: limpiarUsuario ? null : usuario ?? this.usuario,
      usuarios: usuarios ?? this.usuarios,
      error: limpiarError ? null : error ?? this.error,
      cargandoSesion: cargandoSesion ?? this.cargandoSesion,
    );
  }
}
