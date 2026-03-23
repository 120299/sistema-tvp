import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/image_storage_service.dart';
import '../providers/providers.dart';

import '../widgets/ticket_widget.dart';

class VentaLibreScreen extends ConsumerStatefulWidget {
  const VentaLibreScreen({super.key});

  @override
  ConsumerState<VentaLibreScreen> createState() => _VentaLibreScreenState();
}

class _VentaLibreScreenState extends ConsumerState<VentaLibreScreen> {
  final List<PedidoItem> _carrito = [];
  String? _mesaAsignada;
  double _porcentajePropina = 0;
  final TextEditingController _buscadorController = TextEditingController();
  String _textoBusqueda = '';

  @override
  Widget build(BuildContext context) {
    ref.watch(imageRefreshTriggerProvider);
    final productosFiltrados = ref.watch(productosFiltradosProvider);
    final categorias = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);
    final mesas = ref.watch(mesasProvider);
    final todosProductos = ref.watch(productosProvider);

    final productosAMostrar = _textoBusqueda.isNotEmpty
        ? todosProductos
              .where(
                (p) => p.nombre.toLowerCase().contains(
                  _textoBusqueda.toLowerCase(),
                ),
              )
              .toList()
        : productosFiltrados;

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildHeader(),
                _buildCategorias(categoriaSeleccionada, categorias),
                _buildBuscador(),
                Expanded(child: _buildGridProductos(productosAMostrar)),
              ],
            ),
          ),
          Container(width: 1, color: Colors.grey.shade300),
          SizedBox(width: 380, child: _buildPanelCarrito(mesas)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punto de Venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Vende productos y asigna mesa después',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_carrito.fold(0, (sum, item) => sum + item.cantidad)} items',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorias(
    String? categoriaSeleccionada,
    List<CategoriaProducto> categorias,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categorías',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoriaChip(
                  'Todos',
                  null,
                  categoriaSeleccionada == null,
                  Icons.apps,
                ),
                const SizedBox(width: 10),
                ...categorias.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 10),
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
        ],
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _buscadorController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _textoBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _buscadorController.clear();
                    setState(() => _textoBusqueda = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() => _textoBusqueda = value),
      ),
    );
  }

  Widget _buildCategoriaChip(
    String label,
    String? value,
    bool selected,
    IconData icon, [
    String? emoji,
    Color? color,
  ]) {
    final catColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: () =>
          ref.read(categoriaSeleccionadaProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? catColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? catColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 16)),
            if (emoji != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridProductos(List<Producto> productos) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 900) crossAxisCount = 3;
        if (constraints.maxWidth < 600) crossAxisCount = 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
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
    final categoria = ref
        .read(categoriasProvider)
        .firstWhere(
          (c) => c.id == producto.categoriaId,
          orElse: () => CategoriaProducto.defaultCategories.first,
        );

    return GestureDetector(
      onTap: producto.disponible ? () => _agregarAlCarrito(producto) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: producto.disponible
              ? null
              : Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildProductImage(producto, categoria),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          producto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${producto.precio.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!producto.disponible)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
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
              ),
            if (producto.esAlergenico)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.warning,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(CategoriaProducto categoria) {
    return Container(
      color: categoria.color.withValues(alpha: 0.1),
      child: Center(
        child: Text(categoria.icono, style: const TextStyle(fontSize: 40)),
      ),
    );
  }

  Widget _buildProductImage(Producto producto, CategoriaProducto categoria) {
    if (producto.imagenUrl != null && producto.imagenUrl!.isNotEmpty) {
      if (producto.imagenUrl!.startsWith('products/')) {
        final base64 = imageStorageService.getBase64FromPath(
          producto.imagenUrl!,
        );
        if (base64.isNotEmpty) {
          return Image.memory(
            base64Decode(base64),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(categoria),
          );
        }
      } else if (producto.imagenUrl!.startsWith('http')) {
        return Image.network(
          producto.imagenUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(categoria),
        );
      }
    }
    return _buildPlaceholder(categoria);
  }

  Widget _buildPanelCarrito(List<Mesa> mesas) {
    final negocio = ref.watch(negocioProvider);
    final total = _calcularTotal();
    final totalConPropina = total * (1 + _porcentajePropina / 100);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Carrito',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_carrito.length} items',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (_carrito.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Carrito vacío',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toca los productos para agregarlos',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _carrito.length,
                itemBuilder: (context, index) {
                  final item = _carrito[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.error,
                            onPressed: () => _disminuirCantidad(index),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${item.cantidad}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.success,
                            onPressed: () => _aumentarCantidad(index),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productoNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.precioUnitario.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.subtotal.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Base imponible:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text('${(total / 1.10).toStringAsFixed(2)} €'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IVA (${negocio.ivaPorcentaje.toStringAsFixed(0)}%):',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Text('${(total - total / 1.10).toStringAsFixed(2)} €'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Propina:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    ...[0, 5, 10, 15].map(
                      (pct) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text('$pct%'),
                          selected: _porcentajePropina == pct,
                          onSelected: (s) => setState(
                            () => _porcentajePropina = s ? pct.toDouble() : 0,
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalConPropina.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMesaSelector(mesas),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _carrito.isNotEmpty
                            ? () => _generarTicket(negocio)
                            : null,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Ticket'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _carrito.isNotEmpty
                            ? () => _cobrar(negocio)
                            : null,
                        icon: const Icon(Icons.payment),
                        label: const Text('Cobrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesaSelector(List<Mesa> mesas) {
    final mesasOcupadas = ref
        .watch(mesasProvider)
        .where((m) => m.estado == EstadoMesa.ocupada)
        .toList();

    return DropdownButtonFormField<String?>(
      value: _mesaAsignada,
      decoration: const InputDecoration(
        labelText: 'Asignar a mesa (opcional)',
        prefixIcon: Icon(Icons.table_restaurant),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Sin mesa')),
        ...mesasOcupadas.map(
          (m) => DropdownMenuItem(
            value: m.id,
            child: Text('Mesa ${m.numero} (ocupada)'),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _mesaAsignada = value),
    );
  }

  double _calcularTotal() {
    return _carrito.fold<double>(0, (sum, item) => sum + item.subtotal);
  }

  void _agregarAlCarrito(Producto producto) {
    final existente = _carrito.indexWhere((i) => i.productoId == producto.id);
    if (existente >= 0) {
      setState(() {
        _carrito[existente] = _carrito[existente].copyWith(
          cantidad: _carrito[existente].cantidad + 1,
        );
      });
    } else {
      setState(() {
        _carrito.add(
          PedidoItem(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
            productoId: producto.id,
            productoNombre: producto.nombre,
            cantidad: 1,
            precioUnitario: producto.precio,
          ),
        );
      });
    }
  }

  void _eliminarDelCarrito(int index) {
    setState(() => _carrito.removeAt(index));
  }

  void _aumentarCantidad(int index) {
    setState(() {
      _carrito[index] = _carrito[index].copyWith(
        cantidad: _carrito[index].cantidad + 1,
      );
    });
  }

  void _disminuirCantidad(int index) {
    if (_carrito[index].cantidad > 1) {
      setState(() {
        _carrito[index] = _carrito[index].copyWith(
          cantidad: _carrito[index].cantidad - 1,
        );
      });
    } else {
      _eliminarDelCarrito(index);
    }
  }

  void _generarTicket(DatosNegocio negocio) {
    final total = _calcularTotal();
    final totalConPropina = total * (1 + _porcentajePropina / 100);
    final baseImponible = total / (1 + negocio.ivaPorcentaje / 100);
    final importeIva = total - baseImponible;
    final now = DateTime.now();
    final numeroTicket =
        'T-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    negocio.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (negocio.razonSocial != null)
                    Text(
                      negocio.razonSocial!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  Text(negocio.direccion, style: const TextStyle(fontSize: 11)),
                  Text(negocio.ciudad, style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    'CIF/NIF: ${negocio.cifNif ?? "N/A"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nº Ticket: $numeroTicket',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      'PVP',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Importe',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ..._carrito.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${item.cantidad}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.productoNombre,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${item.precioUnitario.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Base imponible:',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${baseImponible.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IVA (${negocio.ivaPorcentaje.toStringAsFixed(0)}%):',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '${importeIva.toStringAsFixed(2)} €',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  if (_porcentajePropina > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Propina (${_porcentajePropina.toStringAsFixed(0)}%):',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '+${(total * _porcentajePropina / 100).toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${totalConPropina.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    'FACTURA SIMPLIFICADA',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sin efectos fiscales según Real Decreto 1496/2003',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '¡Gracias por su visita!',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cobrar(DatosNegocio negocio) {
    final total = _calcularTotal();
    final totalConPropina = total * (1 + _porcentajePropina / 100);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CobroDialog(
        total: totalConPropina,
        onPago: (metodoPago, importeRecibido, cambio) {
          _procesarPago(metodoPago, importeRecibido, cambio);
        },
      ),
    );
  }

  void _procesarPago(
    String metodoPago,
    double? importeRecibido,
    double cambio,
  ) async {
    final negocio = ref.read(negocioProvider);
    final total = _calcularTotal();
    final totalConPropina = total * (1 + _porcentajePropina / 100);
    String? mesaNumero;

    final itemsParaTicket = List<PedidoItem>.from(_carrito);

    if (_mesaAsignada != null) {
      final pedidoId = await ref
          .read(pedidosProvider.notifier)
          .crear(_mesaAsignada!);
      for (final item in _carrito) {
        final producto = ref
            .read(productosProvider)
            .firstWhere((p) => p.id == item.productoId);
        await ref
            .read(pedidosProvider.notifier)
            .agregarItem(pedidoId, producto, cantidad: item.cantidad);
      }
      await ref.read(pedidosProvider.notifier).cerrar(pedidoId, metodoPago);

      final mesa = ref.read(mesasProvider.notifier).getPorId(_mesaAsignada!);
      mesaNumero = mesa?.numero.toString();
    } else {
      final pedidoId = await ref
          .read(pedidosProvider.notifier)
          .crear('sin_mesa');
      for (final item in _carrito) {
        final producto = ref
            .read(productosProvider)
            .firstWhere((p) => p.id == item.productoId);
        await ref
            .read(pedidosProvider.notifier)
            .agregarItem(pedidoId, producto, cantidad: item.cantidad);
      }
      await ref.read(pedidosProvider.notifier).cerrar(pedidoId, metodoPago);
    }

    setState(() {
      _carrito.clear();
      _mesaAsignada = null;
      _porcentajePropina = 0;
    });

    TicketPrintHelper.showPrintDialog(
      context,
      items: itemsParaTicket,
      total: totalConPropina,
      porcentajePropina: _porcentajePropina,
      ivaPorcentaje: negocio.ivaPorcentaje,
      metodoPago: metodoPago,
      negocio: negocio,
      mesaNumero: mesaNumero,
      onImprimir: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abriendo diálogo de impresión...'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
      onCerrar: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta completada con $metodoPago'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class _CobroDialog extends StatefulWidget {
  final double total;
  final Function(String metodoPago, double? importeRecibido, double cambio)
  onPago;

  const _CobroDialog({required this.total, required this.onPago});

  @override
  State<_CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends State<_CobroDialog> {
  String _metodoPago = 'Efectivo';
  final _efectivoController = TextEditingController();
  double _cambio = 0;

  @override
  void dispose() {
    _efectivoController.dispose();
    super.dispose();
  }

  void _calcularCambio() {
    if (_efectivoController.text.isEmpty) {
      setState(() => _cambio = 0);
      return;
    }
    final importe = double.tryParse(_efectivoController.text) ?? 0;
    setState(() => _cambio = importe - widget.total);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total a Cobrar',
              style: TextStyle(color: AppColors.primary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.total.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Método de pago:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetodoPagoButton(
                    Icons.money,
                    'Efectivo',
                    'Efectivo',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetodoPagoButton(
                    Icons.credit_card,
                    'Tarjeta',
                    'Tarjeta',
                  ),
                ),
              ],
            ),
            if (_metodoPago == 'Efectivo') ...[
              const SizedBox(height: 20),
              TextField(
                controller: _efectivoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Importe recibido',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
                onChanged: (_) => _calcularCambio(),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cambio >= 0
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _cambio >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _cambio >= 0 ? 'Cambio a devolver:' : 'Falta por pagar:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _cambio >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      '${_cambio.abs().toStringAsFixed(2)} €',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _cambio >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _puedeCobrar()
                        ? () {
                            final efectivo = _metodoPago == 'Efectivo'
                                ? double.tryParse(_efectivoController.text) ?? 0
                                : null;
                            Navigator.pop(context);
                            widget.onPago(_metodoPago, efectivo, _cambio);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cobrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodoPagoButton(IconData icono, String texto, String valor) {
    final selected = _metodoPago == valor;
    return GestureDetector(
      onTap: () => setState(() => _metodoPago = valor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 32,
              color: selected ? Colors.white : AppColors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              texto,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _puedeCobrar() {
    if (_metodoPago == 'Tarjeta') return true;
    if (_efectivoController.text.isEmpty) return false;
    final importe = double.tryParse(_efectivoController.text) ?? 0;
    return importe >= widget.total;
  }
}
