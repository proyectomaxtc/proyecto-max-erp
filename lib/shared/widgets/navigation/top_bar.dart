import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/caja/providers/caja_provider.dart';
import '../../../features/clientes/providers/cliente_provider.dart';
import '../../../features/notificaciones/models/app_notification_model.dart';
import '../../../features/notificaciones/providers/notification_provider.dart';
import '../../../features/productos/enums/producto_filter.dart';
import '../../../features/productos/providers/producto_provider.dart';
import '../../../features/ventas/providers/venta_provider.dart';

class TopBar extends ConsumerStatefulWidget {
  final String title;
  final bool compact;

  const TopBar({super.key, required this.title, this.compact = false});

  @override
  ConsumerState<TopBar> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final searchLayerLink = LayerLink();
  OverlayEntry? searchOverlay;

  @override
  void initState() {
    super.initState();
    searchFocusNode.addListener(() {
      if (!searchFocusNode.hasFocus) {
        _hideSearchPreview();
      }
    });

    Future.microtask(() {
      ref.read(productoProvider.notifier).cargarProductos();
      ref.read(clienteProvider.notifier).cargarClientes();
      ref.read(ventaProvider.notifier).cargarVentas();
      ref.read(cajaProvider.notifier).cargarMovimientos();
      ref.read(notificationProvider.notifier).cargarNotificaciones();
    });
  }

  @override
  void dispose() {
    _hideSearchPreview();
    searchFocusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final usuario = auth.usuario;
    final notifications = _notifications();
    final unreadNotifications = auth.esPropietario
        ? ref.watch(notificationProvider).where((item) => !item.leida).length
        : 0;

    if (widget.compact) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: "Buscar",
              onPressed: _showMobileSearch,
              icon: const Icon(Icons.search, color: AppColors.textSecondary),
            ),
            IconButton(
              tooltip: "Notificaciones",
              onPressed: () => _showNotifications(notifications),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textSecondary,
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: usuario?.nombre ?? "Usuario",
              color: AppColors.surface,
              icon: const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.black, size: 18),
              ),
              onSelected: (value) {
                if (value == 'config') {
                  context.go(AppRoutes.configuracion);
                }
                if (value == 'logout') {
                  ref.read(authProvider.notifier).logout();
                  context.go(AppRoutes.login);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(usuario?.nombre ?? "Usuario"),
                ),
                if (auth.esPropietario)
                  const PopupMenuItem(
                    value: 'config',
                    child: Text("Configuracion"),
                  ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text("Cerrar sesion"),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Bienvenido nuevamente",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: CompositedTransformTarget(
              link: searchLayerLink,
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onSubmitted: (value) {
                    _hideSearchPreview();
                    _showSearchResults(value);
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar productos, ventas, clientes...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: "Limpiar",
                            onPressed: () {
                              searchController.clear();
                              _hideSearchPreview();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _showSearchPreview,
                ),
              ),
            ),
          ),
          const SizedBox(width: 25),
          IconButton(
            tooltip: "Notificaciones",
            onPressed: () => _showNotifications(notifications),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.textSecondary,
                ),
                if (unreadNotifications > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Configuracion",
            onPressed: auth.esPropietario
                ? () {
                    context.go(AppRoutes.configuracion);
                  }
                : null,
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario?.nombre ?? "Usuario",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                usuario?.rol ?? "Sin sesion",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMobileSearch() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Buscar"),
          content: TextField(
            autofocus: true,
            controller: searchController,
            decoration: const InputDecoration(
              hintText: "Producto, venta o cliente...",
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              _showSearchResults(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () {
                final value = searchController.text;
                Navigator.pop(context);
                _showSearchResults(value);
              },
              child: const Text("Buscar"),
            ),
          ],
        );
      },
    );
  }

  void _showSearchResults(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    final results = _searchResults(value, productLimit: 8, otherLimit: 6);

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No encontre resultados para '$value'")),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Resultados para '$value'"),
          content: SizedBox(
            width: 560,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = results[index];

                return ListTile(
                  leading: Icon(result.icon, color: AppColors.primary),
                  title: Text(result.title),
                  subtitle: Text(result.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _openSearchResult(result);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSearchPreview(String value) {
    setState(() {});

    final query = value.trim();
    if (query.length < 2 || widget.compact) {
      _hideSearchPreview();
      return;
    }

    final results = _searchResults(query, productLimit: 6, otherLimit: 3);
    if (results.isEmpty) {
      _hideSearchPreview();
      return;
    }

    _hideSearchPreview();
    searchOverlay = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideSearchPreview,
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: searchLayerLink,
                  showWhenUnlinked: false,
                  offset: const Offset(0, 54),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 470,
                      constraints: const BoxConstraints(maxHeight: 360),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .35),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: results.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              result.icon,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              result.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              result.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () {
                              _openSearchResult(result);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(searchOverlay!);
  }

  void _hideSearchPreview() {
    searchOverlay?.remove();
    searchOverlay = null;
  }

  void _openSearchResult(_SearchResult result) {
    _hideSearchPreview();
    searchFocusNode.unfocus();
    searchController.text = result.searchText;
    context.go(result.route);

    Future.microtask(result.onOpen);
  }

  List<_SearchResult> _searchResults(
    String value, {
    required int productLimit,
    required int otherLimit,
  }) {
    final query = value.trim().toLowerCase();
    final auth = ref.read(authProvider);
    final sucursal = ref.read(productoProvider).sucursalSeleccionada;
    final productos = ref
        .read(productoProvider)
        .productos
        .where((producto) {
          final texto = [
            producto.codigo,
            producto.codigoBarras,
            producto.nombre,
            producto.categoria,
            producto.marca,
            producto.proveedor,
          ].join(' ').toLowerCase();
          return texto.contains(query);
        })
        .take(productLimit);
    final ventas = ref
        .read(ventaProvider)
        .ventas
        .where((venta) {
          final texto = [
            venta.numero,
            venta.clienteNombre,
            venta.medioPago,
            venta.estado,
          ].join(' ').toLowerCase();
          return texto.contains(query);
        })
        .take(otherLimit);
    final clientes = auth.esPropietario
        ? ref
              .read(clienteProvider)
              .clientes
              .where((cliente) {
                final texto = [
                  cliente.nombre,
                  cliente.apellido,
                  cliente.telefono,
                  cliente.email,
                  cliente.cuit,
                ].join(' ').toLowerCase();
                return texto.contains(query);
              })
              .take(otherLimit)
        : ref.read(clienteProvider).clientes.where((cliente) => false);

    return [
      ...productos.map(
        (producto) => _SearchResult(
          icon: Icons.inventory_2_outlined,
          title: producto.nombre,
          subtitle:
              '${producto.codigo} - Stock ${producto.stockEnSucursal(sucursal).toStringAsFixed(0)} - ${CurrencyFormatter.format(producto.precio)}',
          route: AppRoutes.productos,
          searchText: producto.nombre,
          onOpen: () {
            ref
                .read(productoProvider.notifier)
                .cambiarFiltro(ProductoFilter.todos);
            ref.read(productoProvider.notifier).buscar(producto.nombre);
          },
        ),
      ),
      ...ventas.map(
        (venta) => _SearchResult(
          icon: Icons.sell_outlined,
          title: venta.numero,
          subtitle:
              '${venta.clienteNombre} - ${CurrencyFormatter.format(venta.total)} - ${venta.estado}',
          route: AppRoutes.ventas,
          searchText: venta.numero,
          onOpen: () {
            ref.read(ventaProvider.notifier).buscar(venta.numero);
          },
        ),
      ),
      ...clientes.map(
        (cliente) => _SearchResult(
          icon: Icons.person_search_outlined,
          title: '${cliente.nombre} ${cliente.apellido}'.trim(),
          subtitle: cliente.telefono.isEmpty ? cliente.email : cliente.telefono,
          route: AppRoutes.clientes,
          searchText: '${cliente.nombre} ${cliente.apellido}'.trim(),
          onOpen: () {
            ref
                .read(clienteProvider.notifier)
                .buscar('${cliente.nombre} ${cliente.apellido}'.trim());
          },
        ),
      ),
    ];
  }

  List<_NotificationItem> _notifications() {
    final productos = ref.watch(productoProvider).productos;
    final caja = ref.watch(cajaProvider);
    final auth = ref.watch(authProvider);
    final persisted = auth.esPropietario ? ref.watch(notificationProvider) : [];
    final sinStock = productos
        .where((producto) => producto.activo && producto.stock <= 0)
        .length;
    final stockBajo = productos
        .where(
          (producto) =>
              producto.activo &&
              producto.stock > 0 &&
              producto.stock <= producto.stockMinimo,
        )
        .length;
    final items = <_NotificationItem>[];

    items.addAll(
      persisted
          .take(12)
          .map(
            (notification) => _NotificationItem(
              icon: _iconForNotification(notification),
              title: notification.titulo,
              subtitle:
                  '${notification.usuario} - ${notification.sucursal} - ${notification.detalle}',
              route: notification.ruta,
            ),
          ),
    );

    if (sinStock > 0) {
      items.add(
        _NotificationItem(
          icon: Icons.remove_shopping_cart_outlined,
          title: "$sinStock productos sin stock",
          subtitle: "Revisar reposicion en Productos",
          route: AppRoutes.productos,
        ),
      );
    }

    if (stockBajo > 0) {
      items.add(
        _NotificationItem(
          icon: Icons.warning_amber_outlined,
          title: "$stockBajo productos con stock bajo",
          subtitle: "Requieren seguimiento",
          route: AppRoutes.productos,
        ),
      );
    }

    items.add(
      _NotificationItem(
        icon: caja.cajaAbierta ? Icons.lock_open : Icons.lock_outline,
        title: caja.cajaAbierta ? "Caja abierta" : "Caja cerrada",
        subtitle: caja.cajaAbierta
            ? "Turno: ${caja.turnoAbierto?.responsable ?? 'Sin responsable'}"
            : "Abra caja antes de registrar ventas completadas",
        route: AppRoutes.caja,
      ),
    );

    return items;
  }

  void _showNotifications(List<_NotificationItem> notifications) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Notificaciones"),
          content: SizedBox(
            width: 500,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = notifications[index];

                return ListTile(
                  leading: Icon(item.icon, color: AppColors.primary),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    this.context.go(item.route);
                  },
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      if (ref.read(authProvider).esPropietario) {
        ref.read(notificationProvider.notifier).marcarTodasLeidas();
      }
    });
  }

  IconData _iconForNotification(AppNotificationModel notification) {
    return switch (notification.tipo) {
      'Venta' => Icons.sell_outlined,
      'Caja' => Icons.point_of_sale_outlined,
      'Servicio' => Icons.key_outlined,
      _ => Icons.notifications_none_rounded,
    };
  }
}

class _SearchResult {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final String searchText;
  final VoidCallback onOpen;

  const _SearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.searchText,
    required this.onOpen,
  });
}

class _NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}
