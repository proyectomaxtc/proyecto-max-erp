class ConfiguracionModel {
  final String empresa;
  final String sistema;
  final String slogan;
  final String ownerPin;
  final List<String> categoriasProducto;

  const ConfiguracionModel({
    required this.empresa,
    required this.sistema,
    required this.slogan,
    required this.ownerPin,
    required this.categoriasProducto,
  });

  factory ConfiguracionModel.defaults() {
    return const ConfiguracionModel(
      empresa: 'Tucuman Cerraduras',
      sistema: 'Proyecto MAX ERP',
      slogan: 'Sistema Integral de Gestion',
      ownerPin: '1234',
      categoriasProducto: [
        'Llaves doble paleta',
        'Llaves yale',
        'Llaves computadas',
        'Cerraduras doble paleta',
        'Cerraduras corredizas',
        'Cerraduras de embutir',
        'Cerraduras de aplicar',
        'Cilindros',
        'Candados',
        'Picaportes',
        'Herrajes',
        'Controles remotos',
        'Automotor',
        'Accesorios',
        'Herramientas',
        'Insumos',
        'Otros',
      ],
    );
  }

  ConfiguracionModel copyWith({
    String? empresa,
    String? sistema,
    String? slogan,
    String? ownerPin,
    List<String>? categoriasProducto,
  }) {
    return ConfiguracionModel(
      empresa: empresa ?? this.empresa,
      sistema: sistema ?? this.sistema,
      slogan: slogan ?? this.slogan,
      ownerPin: ownerPin ?? this.ownerPin,
      categoriasProducto: categoriasProducto ?? this.categoriasProducto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresa': empresa,
      'sistema': sistema,
      'slogan': slogan,
      'ownerPin': ownerPin,
      'categoriasProducto': categoriasProducto,
    };
  }

  factory ConfiguracionModel.fromMap(Map<dynamic, dynamic> map) {
    final defaults = ConfiguracionModel.defaults();
    final categorias = (map['categoriasProducto'] as List?)
            ?.map((categoria) => categoria.toString().trim())
            .where((categoria) => categoria.isNotEmpty)
            .toList() ??
        defaults.categoriasProducto;

    return ConfiguracionModel(
      empresa: map['empresa'] as String? ?? 'Tucuman Cerraduras',
      sistema: map['sistema'] as String? ?? 'Proyecto MAX ERP',
      slogan: map['slogan'] as String? ?? 'Sistema Integral de Gestion',
      ownerPin: map['ownerPin'] as String? ?? '1234',
      categoriasProducto: categorias,
    );
  }
}
