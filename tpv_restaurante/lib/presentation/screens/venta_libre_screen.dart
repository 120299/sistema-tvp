import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../../data/services/print_service.dart';
import '../widgets/producto_personalizacion_dialog.dart';
import '../widgets/product_image_widget.dart';
import '../providers/providers.dart';
import 'cobro_sheet.dart';

class VentaLibreScreen extends ConsumerStatefulWidget {
  const VentaLibreScreen({super.key});

  @override
  ConsumerState<VentaLibreScreen> createState() => _VentaLibreScreenState();
}

class _VentaLibreScreenState extends ConsumerState<VentaLibreScreen> {
  final List<PedidoItem> _carrito = [];
  String? _mesaAsignada;
  final TextEditingController _buscadorController = TextEditingController();
  bool _mesaCargada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarMesaInicial();
    });
  }

  Future<void> _cargarMesaInicial() async {
    if (_mesaCargada) return;
    final mesaId = ref.read(mesaVentaSeleccionadaProvider);
    if (mesaId != null && mounted) {
      _mesaCargada = true;
      ref.read(mesaVentaSeleccionadaProvider.notifier).state = null;
      setState(() {
        _mesaAsignada = mesaId;
      });
      await _cargarProductosMesa(mesaId);
    }
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(imageRefreshTriggerProvider);
    final caja = ref.watch(cajaProvider);
    final productosFiltrados = ref.watch(productosFiltradosProvider);
    final categoriasRaw = ref.watch(categoriasProvider);
    final categoriasOrdenadas = List<CategoriaProducto>.from(categoriasRaw)
      ..sort((a, b) => a.orden.compareTo(b.orden));
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final todasMesas = ref.watch(mesasProvider);

    final mesasDisponibles = todasMesas
        .where((m) => m.estado == EstadoMesa.libre)
        .toList();

    // Los productos ya vienen filtrados por el provider compartido
    final productosAMostrar = productosFiltrados;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildHeader(mesasDisponibles, caja: caja, isWide: true),
                      _buildCategorias(
                        categoriaSeleccionada,
                        categoriasOrdenadas,
                      ),
                      _buildBuscador(),
                      Expanded(child: _buildGridProductos(productosAMostrar)),
                    ],
                  ),
                ),
                Container(width: 1, color: AppColors.lightDivider),
                SizedBox(width: 380, child: _buildPanelCarrito()),
              ],
            );
          } else {
            return Column(
              children: [
                _buildHeader(mesasDisponibles, caja: caja, isWide: false),
                _buildCategorias(categoriaSeleccionada, categoriasOrdenadas),
                _buildBuscador(),
                Expanded(child: _buildGridProductos(productosAMostrar)),
                _buildCarritoBarra(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCarritoBarra() {
    if (_carrito.isEmpty) return const SizedBox.shrink();

    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_carrito.fold<int>(0, (sum, i) => sum + i.cantidad)} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${total.toStringAsFixed(2)} €',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _cobrarPedido,
              icon: const Icon(Icons.payment),
              label: const Text('Cobrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _verCarritoCompleto,
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _verCarritoCompleto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            _buildPanelCarrito(scrollController: scrollController),
      ),
    );
  }

  Widget _buildHeader(
    List<Mesa> mesasDisponibles, {
    Caja? caja,
    bool isWide = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.point_of_sale,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Punto de Venta',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: AppColors.lightDivider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _mesaAsignada,
                        isExpanded: true,
                        hint: const Row(
                          children: [
                            Icon(
                              Icons.table_restaurant,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '/',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.table_restaurant,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '/ (Sin mesa)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          ...mesasDisponibles.map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mesa ${m.numero}'),
                                ],
                              ),
                            ),
                          ),
                          ..._getMesasOcupadas().map(
                            (m) => DropdownMenuItem(
                              value: m.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.table_restaurant,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Mesa ${m.numero}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == _mesaAsignada) return;

                          setState(() {
                            _mesaAsignada = value;
                            _carrito.clear();
                          });

                          if (value != null) {
                            await _cargarProductosMesa(value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_mesaAsignada != null && _carrito.isNotEmpty) ...[
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.error,
                    onPressed: () {
                      _mostrarDialogoLiberarMesa();
                    },
                    tooltip: 'Liberar mesa',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLiberarMesa() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppColors.warning),
            SizedBox(width: 12),
            Text('Liberar Mesa'),
          ],
        ),
        content: const Text(
          '¿Deseas liberar esta mesa? Se eliminará el pedido actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_mesaAsignada != null) {
                final mesa = ref
                    .read(mesasProvider)
                    .where((m) => m.id == _mesaAsignada)
                    .firstOrNull;
                final pedidoId = mesa?.pedidoActualId;
                await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
                if (pedidoId != null) {
                  await ref.read(pedidosProvider.notifier).eliminar(pedidoId);
                }
                ref.read(pedidosProvider.notifier).actualizarLista();
                ref.read(mesasProvider.notifier).actualizarLista();
              }
              setState(() {
                _mesaAsignada = null;
                _carrito.clear();
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Liberar'),
          ),
        ],
      ),
    );
  }

  List<Mesa> _getMesasOcupadas() {
    final todasMesas = ref.read(mesasProvider);
    return todasMesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
  }

  Widget _buildCategorias(
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoriaChip(
                  'Todos',
                  null,
                  categoriaSeleccionada == null,
                  Icons.apps,
                ),
                const SizedBox(width: 8),
                ...categorias.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoriaChip(
                      cat.nombre,
                      cat.id,
                      categoriaSeleccionada == cat.id,
                      Icons.category,
                      cat.icono,
                      cat.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _mostrarModalCategorias(
              context,
              categoriaSeleccionada,
              categorias,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalCategorias(
    BuildContext context,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final cats = ref.watch(categoriasProvider);
            final sorted = List<CategoriaProducto>.from(cats)
              ..sort((a, b) => a.orden.compareTo(b.orden));

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Categorías',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildGridCategorias(
                        ctx,
                        categoriaSeleccionada,
                        sorted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridCategorias(
    BuildContext ctx,
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.3,
      ),
      itemCount: categorias.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final isSelected = categoriaSeleccionada == null;
          return GestureDetector(
            onTap: () {
              ref.read(categoriaSeleccionadaProvider.notifier).state = null;
              Navigator.pop(ctx);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.grey.shade50,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    size: 28,
                    color: isSelected ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Todos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        final cat = categorias[index - 1];
        final isSelected = categoriaSeleccionada == cat.id;
        return GestureDetector(
          onTap: () {
            ref.read(categoriaSeleccionadaProvider.notifier).state = cat.id;
            Navigator.pop(ctx);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cat.color.withValues(alpha: 0.15)
                  : Colors.grey.shade50,
              border: Border.all(
                color: isSelected ? cat.color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (cat.icono.isNotEmpty)
                  Text(cat.icono, style: const TextStyle(fontSize: 28))
                else
                  Icon(
                    Icons.category,
                    size: 28,
                    color: isSelected ? cat.color : Colors.grey,
                  ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.nombre,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? cat.color : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriaChip(
    String label,
    String? id,
    bool selected,
    IconData icon, [
    String? icono,
    Color? color,
  ]) {
    return ActionChip(
      avatar: icono != null
          ? Text(icono, style: const TextStyle(fontSize: 14))
          : Icon(
              selected ? Icons.check : icon,
              size: 16,
              color: selected ? (color ?? AppColors.primary) : Colors.grey,
            ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? (color ?? AppColors.primary) : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: selected
          ? (color ?? AppColors.primary).withValues(alpha: 0.15)
          : Colors.grey.shade100,
      side: BorderSide(
        color: selected ? (color ?? AppColors.primary) : Colors.grey.shade300,
      ),
      onPressed: () {
        ref.read(categoriaSeleccionadaProvider.notifier).state = selected
            ? null
            : id;
      },
    );
  }

  Widget _buildBuscador() {
    final busquedaCompartida = ref.watch(busquedaCompartidaProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _buscadorController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _buscadorController.text.isNotEmpty ||
                        busquedaCompartida.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscadorController.clear();
                          ref.read(busquedaCompartidaProvider.notifier).state =
                              '';
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                ref.read(busquedaCompartidaProvider.notifier).state = value;
              },
            ),
          ),
          const SizedBox(width: 12),
          // Indicador de filtros activos
          if (busquedaCompartida.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Buscando: "$busquedaCompartida"',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridProductos(List<Producto> productos) {
    if (productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay productos',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        if (width > 1200) {
          crossAxisCount = 6;
        } else if (width > 900) {
          crossAxisCount = 5;
        } else if (width > 600) {
          crossAxisCount = 4;
        } else if (width > 400) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 5 / 4,
          ),
          itemCount: productos.length,
          itemBuilder: (context, index) {
            final producto = productos[index];
            return _buildProductCard(producto);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Producto producto) {
    final itemEnCarrito = _carrito
        .where((i) => i.productoId == producto.id)
        .firstOrNull;
    final categorias = ref.read(categoriasProvider);
    final categoria = categorias
        .where((c) => c.id == producto.categoriaId)
        .firstOrNull;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: producto.disponible ? () => _agregarProducto(producto) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(producto, categoria),
                  if (!producto.disponible)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Text(
                          'AGOTADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (itemEnCarrito != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Text(
                          '${itemEnCarrito.cantidad}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: producto.disponible ? null : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildPrecioProducto(producto),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Producto producto, CategoriaProducto? categoria) {
    return ProductImageWidget(producto: producto, categoria: categoria);
  }

  Widget _buildPrecioProducto(Producto producto) {
    final color = producto.disponible ? AppColors.secondary : Colors.grey;

    if (producto.esVariable &&
        producto.precio == 0 &&
        (producto.variantes?.isNotEmpty ?? false)) {
      final precios = producto.variantes!.map((v) => v.precio).toList();
      final precioMin = precios.reduce((a, b) => a < b ? a : b);
      final precioMax = precios.reduce((a, b) => a > b ? a : b);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (precioMin == precioMax)
            Text(
              '${precioMin.toStringAsFixed(2)} EUR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          else
            Text(
              '${precioMin.toStringAsFixed(2)} - ${precioMax.toStringAsFixed(2)} EUR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          Text(
            '${producto.variantes!.length} vars',
            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    return Text(
      '${producto.precio.toStringAsFixed(2)} EUR',
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildPlaceholder(CategoriaProducto? categoria) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (categoria?.color ?? AppColors.primary).withValues(alpha: 0.2),
            (categoria?.color ?? AppColors.primary).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Text(
          categoria?.icono ?? '🍽️',
          style: const TextStyle(fontSize: 36),
        ),
      ),
    );
  }

  Widget _buildPanelCarrito({ScrollController? scrollController}) {
    if (_carrito.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Carrito vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 8),
              Text(
                'Toca productos para añadir',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    final total = _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);
    final caja = ref.watch(cajaProvider);
    final mesaSeleccionada = _mesaAsignada != null
        ? ref
              .read(mesasProvider)
              .where((m) => m.id == _mesaAsignada)
              .firstOrNull
        : null;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pedido (${_carrito.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (mesaSeleccionada != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.table_restaurant,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mesa ${mesaSeleccionada.numero}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                if (caja != null && caja.estado == EstadoCaja.abierta)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.lock_open,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () async {
                        try {
                          await PrintService.abrirCajon();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comando enviado al cajón'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      tooltip: 'Abrir Cajón',
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _carrito.length,
              itemBuilder: (context, index) {
                final item = _carrito[index];
                return _buildCarritoItem(item, index, () {
                  setState(() {
                    _carrito.removeAt(index);
                  });
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              border: Border(top: BorderSide(color: AppColors.lightDivider)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cobrarPedido,
                    icon: const Icon(Icons.payment, size: 24),
                    label: const Text(
                      'COBRAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final caja = ref.read(cajaProvider);
                      if (caja != null && caja.estado == EstadoCaja.abierta) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('La caja ya está abierta'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                        return;
                      }
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Abrir Caja'),
                          content: const Text('¿Abrir la caja?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Abrir'),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true) {
                        await ref
                            .read(cajaProvider.notifier)
                            .abrirCaja(fondoInicial: 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Caja abierta'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.lock_open, size: 20),
                    label: const Text(
                      'ABRIR CAJA',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarritoItem(PedidoItem item, int index, VoidCallback onRemove) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar producto'),
                content: Text(
                  '¿Eliminar "${item.productoNombre}" del carrito?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        if (_mesaAsignada != null) {
          final pedidoId = ref
              .read(mesasProvider)
              .where((m) => m.id == _mesaAsignada)
              .firstOrNull
              ?.pedidoActualId;
          if (pedidoId != null) {
            await ref
                .read(pedidosProvider.notifier)
                .eliminarItem(pedidoId, item.id);

            ref.read(pedidosProvider.notifier).actualizarLista();
            final pedidoActualizado = ref
                .read(pedidosProvider)
                .where((p) => p.id == pedidoId)
                .firstOrNull;
            if (pedidoActualizado != null && pedidoActualizado.items.isEmpty) {
              await ref
                  .read(pedidosProvider.notifier)
                  .eliminar(pedidoActualizado.id);
              await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
              setState(() {
                _mesaAsignada = null;
              });
            }
          }
        }
        onRemove();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.cantidad}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.productoNombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.precioUnitario.toStringAsFixed(2)} € x${item.cantidad}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (item.cantidad > 1) {
                      _actualizarCantidad(item, item.cantidad - 1);
                    } else {
                      _eliminarProductoPorId(item.id);
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.remove,
                      color: AppColors.error,
                      size: 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${item.cantidad}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () => _actualizarCantidad(item, item.cantidad + 1),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add,
                      color: AppColors.success,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _mostrarDialogoEditarPrecio(item, index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _eliminarProductoPorId(item.id),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _agregarProducto(Producto producto) async {
    final caja = ref.read(cajaProvider);
    if (caja == null || caja.estado != EstadoCaja.abierta) {
      _mostrarAlertaCajaCerrada();
      return;
    }

    if (producto.estaAgotado) {
      _mostrarAlertaStockAgotado(producto);
      return;
    }

    final esConfigurable =
        producto.esVariable ||
        (producto.ingredientes?.isNotEmpty ?? false) ||
        (producto.extras?.isNotEmpty ?? false);

    if (esConfigurable) {
      final resultado = await showDialog<PedidoItem>(
        context: context,
        builder: (ctx) => ProductoPersonalizacionDialog(
          producto: producto,
          onConfirm: (item) => Navigator.pop(ctx, item),
        ),
      );

      if (resultado != null) {
        await _agregarItemAlCarrito(producto, resultado);
      }
      return;
    }

    final itemExistente = _carrito
        .where((i) => i.productoId == producto.id)
        .firstOrNull;

    if (itemExistente != null) {
      final index = _carrito.indexOf(itemExistente);
      setState(() {
        _carrito[index] = itemExistente.copyWith(
          cantidad: itemExistente.cantidad + 1,
        );
      });
      if (_mesaAsignada != null) {
        await _actualizarItemBD(itemExistente, itemExistente.cantidad + 1);
      }
    } else {
      final nuevoItem = PedidoItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productoId: producto.id,
        productoNombre: producto.nombre,
        cantidad: 1,
        precioUnitario: producto.precio,
      );
      setState(() {
        _carrito.add(nuevoItem);
      });
      if (_mesaAsignada != null) {
        await _agregarItemBD(nuevoItem);
      }
    }
  }

  Future<void> _agregarItemAlCarrito(Producto producto, PedidoItem item) async {
    final itemExistente = _carrito
        .where(
          (i) =>
              i.productoId == producto.id &&
              i.varianteId == item.varianteId &&
              _sonExtrasIguales(
                i.extrasSeleccionados,
                item.extrasSeleccionados,
              ),
        )
        .firstOrNull;

    if (itemExistente != null) {
      final nuevaCantidad = itemExistente.cantidad + item.cantidad;
      final index = _carrito.indexOf(itemExistente);
      setState(() {
        _carrito[index] = itemExistente.copyWith(cantidad: nuevaCantidad);
      });
      if (_mesaAsignada != null) {
        await _actualizarItemBD(itemExistente, nuevaCantidad);
      }
    } else {
      setState(() {
        _carrito.add(item);
      });
      if (_mesaAsignada != null) {
        await _agregarItemBD(item);
      }
    }
  }

  bool _sonExtrasIguales(List<ExtraProducto>? a, List<ExtraProducto>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final extra in a) {
      if (!b.any((e) => e.id == extra.id)) return false;
    }
    return true;
  }

  void _mostrarAlertaStockAgotado(Producto producto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Producto Agotado'),
          ],
        ),
        content: Text(
          'El producto "${producto.nombre}" está agotado.\n\n'
          '¿Desea reponer el stock?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Reponer Stock'),
          ),
        ],
      ),
    );
  }

  Future<void> _agregarItemBD(PedidoItem item) async {
    if (_mesaAsignada == null) return;

    // Verificar que la caja esté abierta
    final caja = ref.read(cajaProvider);
    if (caja == null || caja.estado != EstadoCaja.abierta) {
      _mostrarAlertaCajaCerrada();
      return;
    }

    final mesaActual = ref
        .read(mesasProvider)
        .where((m) => m.id == _mesaAsignada)
        .firstOrNull;
    if (mesaActual == null) return;

    String pedidoId = mesaActual.pedidoActualId ?? '';

    // Verificar si el pedido existe en Hive
    if (pedidoId.isNotEmpty) {
      final pedidoExiste = ref
          .read(pedidosProvider)
          .any((p) => p.id == pedidoId);
      if (!pedidoExiste) {
        // Pedido huérfano: limpiar y crear nuevo
        await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
        pedidoId = '';
      }
    }

    if (pedidoId.isEmpty) {
      final cajeroActual = ref.read(cajeroActualProvider);
      pedidoId = await ref
          .read(pedidosProvider.notifier)
          .crear(
            _mesaAsignada!,
            cajeroId: cajeroActual?.id,
            cajeroNombre: cajeroActual?.nombre,
          );
      await ref.read(mesasProvider.notifier).ocupar(_mesaAsignada!, pedidoId);
    }

    // Buscar la variante del producto si tiene una
    VarianteProducto? variante;
    if (item.varianteId != null) {
      final productoCompleto = ref
          .read(productosProvider)
          .where((p) => p.id == item.productoId)
          .firstOrNull;
      if (productoCompleto?.variantes != null) {
        variante = productoCompleto!.variantes!
            .where((v) => v.id == item.varianteId)
            .firstOrNull;
      }
    }

    try {
      await ref
          .read(pedidosProvider.notifier)
          .agregarItem(
            pedidoId,
            Producto(
              id: item.productoId,
              nombre: item.productoNombre.split(' - ').first,
              precio: item.precioUnitario,
              categoriaId: '',
            ),
            cantidad: item.cantidad,
            variante: variante,
            notas: item.notas,
            ingredientesQuitados: item.ingredientesQuitados,
            extrasSeleccionados: item.extrasSeleccionados,
          );
    } catch (e) {
      debugPrint('Error al agregar item a BD: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar producto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _actualizarItemBD(PedidoItem item, int nuevaCantidad) async {
    if (_mesaAsignada == null) return;

    final mesaActual = ref
        .read(mesasProvider)
        .where((m) => m.id == _mesaAsignada)
        .firstOrNull;
    if (mesaActual == null || mesaActual.pedidoActualId == null) return;

    final pedido = ref
        .read(pedidosProvider)
        .where((p) => p.id == mesaActual.pedidoActualId)
        .firstOrNull;
    if (pedido == null) return;

    // Buscar el item por su ID exacto
    final itemEnPedido = pedido.items.where((i) => i.id == item.id).firstOrNull;
    if (itemEnPedido != null) {
      try {
        await ref
            .read(pedidosProvider.notifier)
            .actualizarCantidad(
              mesaActual.pedidoActualId!,
              itemEnPedido.id,
              nuevaCantidad,
            );
      } catch (e) {
        debugPrint('Error al actualizar cantidad: $e');
      }
    }
  }

  void _eliminarProducto(int index) async {
    if (index < 0 || index >= _carrito.length) return;

    final item = _carrito[index];

    setState(() {
      _carrito.removeAt(index);
    });

    if (_mesaAsignada != null) {
      final pedidoId = ref
          .read(mesasProvider)
          .where((m) => m.id == _mesaAsignada)
          .firstOrNull
          ?.pedidoActualId;
      if (pedidoId != null) {
        try {
          await ref
              .read(pedidosProvider.notifier)
              .eliminarItem(pedidoId, item.id);

          ref.read(pedidosProvider.notifier).actualizarLista();
          final pedidoActualizado = ref
              .read(pedidosProvider)
              .where((p) => p.id == pedidoId)
              .firstOrNull;
          if (pedidoActualizado != null && pedidoActualizado.items.isEmpty) {
            await ref
                .read(pedidosProvider.notifier)
                .eliminar(pedidoActualizado.id);
            await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
            setState(() {
              _mesaAsignada = null;
            });
          }
        } catch (e) {
          debugPrint('Error al eliminar item: $e');
        }
      }
    }
  }

  void _mostrarDialogoEditarPrecio(PedidoItem item, int index) {
    final precioController = TextEditingController(
      text: item.precioUnitario.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar precio: ${item.productoNombre}'),
        content: TextField(
          controller: precioController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Precio unitario (€)',
            prefixText: '€ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final nuevoPrecio = double.tryParse(precioController.text);
              if (nuevoPrecio != null && nuevoPrecio > 0) {
                setState(() {
                  _carrito[index] = item.copyWith(precioUnitario: nuevoPrecio);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarProductoPorId(String itemId) {
    final index = _carrito.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _eliminarProducto(index);
    }
  }

  void _actualizarCantidad(PedidoItem item, int nuevaCantidad) async {
    final index = _carrito.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    setState(() {
      if (nuevaCantidad <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index] = item.copyWith(cantidad: nuevaCantidad);
      }
    });

    if (_mesaAsignada != null) {
      await _actualizarItemBD(item, nuevaCantidad);

      if (_carrito.isEmpty) {
        ref.read(pedidosProvider.notifier).actualizarLista();
        ref.read(mesasProvider.notifier).actualizarLista();
        final pedidoId = ref
            .read(mesasProvider)
            .where((m) => m.id == _mesaAsignada)
            .firstOrNull
            ?.pedidoActualId;
        if (pedidoId != null) {
          await ref.read(pedidosProvider.notifier).eliminar(pedidoId);
          await ref.read(mesasProvider.notifier).liberar(_mesaAsignada!);
          setState(() {
            _mesaAsignada = null;
          });
        }
      }
    }
  }

  void _mostrarAlertaCajaCerrada() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.warning_amber, color: AppColors.warning),
            ),
            const SizedBox(width: 12),
            const Text('Caja Cerrada'),
          ],
        ),
        content: const Text(
          'La caja está cerrada. Abre la caja para poder realizar ventas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(indiceNavegacionProvider.notifier).state = 4;
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Ir a Caja'),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarProductosMesa(String mesaId) async {
    try {
      // FORZAR refresh desde la base de datos para evitar datos obsoletos
      ref.read(pedidosProvider.notifier).actualizarLista();
      ref.read(mesasProvider.notifier).actualizarLista();

      final todasMesas = ref.read(mesasProvider);
      final mesa = todasMesas.where((m) => m.id == mesaId).firstOrNull;

      if (mesa == null || mesa.pedidoActualId == null) {
        if (mounted) {
          setState(() => _carrito.clear());
        }
        return;
      }

      final pedido = ref
          .read(pedidosProvider)
          .where((p) => p.id == mesa.pedidoActualId)
          .firstOrNull;

      // Si el pedido no existe en Hive o está cerrado, limpiar la mesa
      if (pedido == null || pedido.estado == EstadoPedido.cerrado) {
        await ref.read(mesasProvider.notifier).liberar(mesaId);
        if (pedido != null) {
          await ref.read(pedidosProvider.notifier).eliminar(pedido.id);
        }
        ref.read(pedidosProvider.notifier).actualizarLista();
        ref.read(mesasProvider.notifier).actualizarLista();
        if (mounted) {
          setState(() => _carrito.clear());
        }
        return;
      }

      if (mounted) {
        setState(() {
          _carrito.clear();
          _carrito.addAll(pedido.items);
        });
      }
    } catch (e) {
      debugPrint('Error cargando productos de mesa: $e');
      if (mounted) {
        setState(() => _carrito.clear());
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.zero,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  void _cobrarPedido() async {
    if (_carrito.isEmpty) return;

    final negocio = ref.read(negocioProvider);
    final subtotal = _carrito.fold<double>(
      0,
      (sum, item) => sum + item.subtotal,
    );
    final total = subtotal;
    final mesaIdActual = _mesaAsignada;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => CobroSheet(
        total: total,
        onCobrar: (metodosPago, {Cliente? cliente}) async {
          try {
            final caja = ref.read(cajaProvider);
            final pedidoId = await ref
                .read(pedidosProvider.notifier)
                .crear(
                  mesaIdActual ?? '',
                  clienteId: cliente?.id,
                  clienteNombre: cliente?.nombre,
                  cajeroId: caja?.cajeroId,
                  cajeroNombre: caja?.cajeroNombre,
                );

            for (final item in _carrito) {
              // Buscar la variante del producto si tiene una
              VarianteProducto? variante;
              if (item.varianteId != null) {
                final productoCompleto = ref
                    .read(productosProvider)
                    .where((p) => p.id == item.productoId)
                    .firstOrNull;
                if (productoCompleto?.variantes != null) {
                  variante = productoCompleto!.variantes!
                      .where((v) => v.id == item.varianteId)
                      .firstOrNull;
                }
              }

              await ref
                  .read(pedidosProvider.notifier)
                  .agregarItem(
                    pedidoId,
                    Producto(
                      id: item.productoId,
                      nombre: item.productoNombre.split(' - ').first,
                      precio: item.precioUnitario,
                      categoriaId: '',
                    ),
                    cantidad: item.cantidad,
                    variante: variante,
                    notas: item.notas,
                    ingredientesQuitados: item.ingredientesQuitados,
                    extrasSeleccionados: item.extrasSeleccionados,
                  );

              await ref
                  .read(productosProvider.notifier)
                  .decrementarStock(item.productoId, item.cantidad);
            }

            final numeroTicket = await ref
                .read(negocioProvider.notifier)
                .obtenerSiguienteNumeroTicket();

            final metodoPrincipal = metodosPago.keys.first;
            final cajaActual = ref.read(cajaProvider);

            await ref
                .read(pedidosProvider.notifier)
                .cerrar(
                  pedidoId,
                  metodoPrincipal,
                  numeroTicket: numeroTicket,
                  cajaId: cajaActual?.id,
                );

            final pedido = ref
                .read(pedidosProvider)
                .where((p) => p.id == pedidoId)
                .firstOrNull;

            await ref
                .read(cajaProvider.notifier)
                .registrarVenta(total, metodoPrincipal, pedidoId: pedidoId);

            if (cliente != null) {
              await ref
                  .read(clientesProvider.notifier)
                  .registrarVenta(cliente.id, total);
            }

            if (mesaIdActual != null) {
              await ref.read(mesasProvider.notifier).liberar(mesaIdActual);
            }

            String? mesaNumero;
            if (mesaIdActual != null) {
              final mesa = ref
                  .read(mesasProvider)
                  .where((m) => m.id == mesaIdActual)
                  .firstOrNull;
              mesaNumero = mesa?.numero.toString();
            }

            final metodoTexto = metodosPago.entries
                .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}€')
                .join(' + ');

            if (!mounted) return;

            try {
              await PrintService.mostrarTicketPreview(
                context: ctx,
                items: List.from(_carrito),
                subtotal: subtotal,
                ivaPorcentaje: negocio.ivaPorcentaje,
                metodoPago: metodoTexto,
                negocio: negocio,
                mesaNumero: mesaNumero,
                cajeroNombre: caja?.cajeroNombre,
                clienteNombre: cliente?.nombre,
                clienteNif: cliente?.nif,
                numeroTicket: numeroTicket,
                fechaVenta: pedido?.horaApertura,
              );
            } catch (e) {
              debugPrint('Error al imprimir ticket: $e');
            }

            if (!mounted) return;
            Navigator.pop(ctx);

            setState(() {
              _carrito.clear();
              _mesaAsignada = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Venta completada'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 1),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
