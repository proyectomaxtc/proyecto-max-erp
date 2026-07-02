import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_max/features/ventas/models/venta_item_model.dart';

void main() {
  test('una venta conserva precio y costo historico', () {
    final ventaOriginal = VentaItemModel(
      productoId: 'producto-1',
      codigo: 'A100',
      nombre: 'Cerradura reforzada',
      cantidad: 2,
      precioUnitario: 1500,
      costoUnitario: 900,
    );

    final ventaRestaurada = VentaItemModel.fromMap(ventaOriginal.toMap());

    expect(ventaRestaurada.precioUnitario, 1500);
    expect(ventaRestaurada.costoUnitario, 900);
    expect(ventaRestaurada.subtotal, 3000);
    expect(ventaRestaurada.costoTotal, 1800);
  });
}
