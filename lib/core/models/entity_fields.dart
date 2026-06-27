/// Campos comunes utilizados por las entidades del sistema.
///
/// No es una clase para heredar.
/// Sirve como referencia y para mantener consistencia
/// entre todos los modelos del ERP.
class EntityFields {
  EntityFields._();

  static const String id = 'id';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isActive = 'isActive';
}