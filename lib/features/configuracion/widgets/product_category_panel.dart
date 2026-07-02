import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/configuracion_provider.dart';

class ProductCategoryPanel extends ConsumerStatefulWidget {
  const ProductCategoryPanel({super.key});

  @override
  ConsumerState<ProductCategoryPanel> createState() =>
      _ProductCategoryPanelState();
}

class _ProductCategoryPanelState extends ConsumerState<ProductCategoryPanel> {
  final categoriaController = TextEditingController();
  String? editando;

  bool get estaEditando => editando != null;

  @override
  void dispose() {
    categoriaController.dispose();
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

  Future<void> guardarCategoria() async {
    final nombre = categoriaController.text.trim();

    if (nombre.isEmpty) {
      return;
    }

    final config = ref.read(configuracionProvider);
    final categorias = [...config.categoriasProducto];
    final existe = categorias.any(
      (categoria) => categoria.toLowerCase() == nombre.toLowerCase(),
    );

    if (existe && !estaEditando) {
      _mensaje('La categoria ya existe', AppColors.warning);
      return;
    }

    if (estaEditando) {
      final index = categorias.indexWhere((categoria) => categoria == editando);
      if (index >= 0) {
        categorias[index] = nombre;
      }
    } else {
      categorias.add(nombre);
    }

    categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    await ref
        .read(configuracionProvider.notifier)
        .guardarConfiguracion(
          config.copyWith(categoriasProducto: categorias),
        );

    limpiar();
    _mensaje('Categorias actualizadas', AppColors.success);
  }

  Future<void> eliminarCategoria(String categoria) async {
    final config = ref.read(configuracionProvider);
    final categorias = config.categoriasProducto
        .where((item) => item != categoria)
        .toList();

    await ref
        .read(configuracionProvider.notifier)
        .guardarConfiguracion(
          config.copyWith(categoriasProducto: categorias),
        );

    if (editando == categoria) {
      limpiar();
    }

    _mensaje('Categoria eliminada', AppColors.success);
  }

  void editar(String categoria) {
    setState(() {
      editando = categoria;
      categoriaController.text = categoria;
    });
  }

  void limpiar() {
    setState(() {
      editando = null;
      categoriaController.clear();
    });
  }

  void _mensaje(String texto, Color color) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: color, content: Text(texto)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categorias = ref.watch(configuracionProvider).categoriasProducto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Categorias de productos",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Esta lista alimenta el desplegable de Nuevo Producto y Editar Producto.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: categoriaController,
                decoration: decoration("Nombre de categoria"),
                onSubmitted: (_) => guardarCategoria(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: guardarCategoria,
              icon: Icon(estaEditando ? Icons.save_outlined : Icons.add),
              label: Text(estaEditando ? "Guardar" : "Agregar"),
            ),
            if (estaEditando) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: limpiar,
                icon: const Icon(Icons.close),
                label: const Text("Cancelar"),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categorias.map((categoria) {
            return InputChip(
              label: Text(categoria),
              avatar: const Icon(Icons.category_outlined, size: 18),
              onPressed: () => editar(categoria),
              onDeleted: categorias.length <= 1
                  ? null
                  : () => eliminarCategoria(categoria),
            );
          }).toList(),
        ),
      ],
    );
  }
}
