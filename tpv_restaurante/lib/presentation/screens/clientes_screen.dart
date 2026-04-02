import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/services/print_service.dart';
import '../providers/providers.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  final _buscadorController = TextEditingController();
  String _textoBusqueda = '';

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientes = ref.watch(clientesProvider);

    final clientesFiltrados = _textoBusqueda.isEmpty
        ? clientes
        : clientes
              .where(
                (c) =>
                    c.nombre.toLowerCase().contains(
                      _textoBusqueda.toLowerCase(),
                    ) ||
                    (c.telefono?.contains(_textoBusqueda) ?? false) ||
                    (c.email?.toLowerCase().contains(
                          _textoBusqueda.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildBuscador(),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? _buildEmptyState()
                : _buildClienteList(clientesFiltrados),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nuevo_cliente',
        onPressed: () => _mostrarDialogoCliente(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Cliente',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final clientes = ref.watch(clientesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${clientes.length} clientes registrados',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscador() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _buscadorController,
        autofocus: false,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, teléfono o email...',
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
          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) => setState(() => _textoBusqueda = value),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _textoBusqueda.isEmpty
                ? 'No hay clientes registrados'
                : 'No se encontraron clientes',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para añadir un cliente',
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteList(List<Cliente> clientes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(cliente);
      },
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mostrarHistorialPedidos(context, cliente),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                alignment: Alignment.center,
                child: Text(
                  cliente.nombre.isNotEmpty
                      ? cliente.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (cliente.telefono != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            cliente.telefono!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (cliente.direccion != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.direccion!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (cliente.totalPedidos > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '${cliente.totalPedidos} pedidos',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${cliente.totalGastado.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCliente(BuildContext context, {Cliente? cliente}) {
    final esEdicion = cliente != null;
    final nombreController = TextEditingController(text: cliente?.nombre ?? '');
    final telefonoController = TextEditingController(
      text: cliente?.telefono ?? '',
    );
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final nifController = TextEditingController(text: cliente?.nif ?? '');
    final direccionController = TextEditingController(
      text: cliente?.direccion ?? '',
    );
    final codigoPostalController = TextEditingController(
      text: cliente?.codigoPostal ?? '',
    );
    final ciudadController = TextEditingController(text: cliente?.ciudad ?? '');
    final poblacionController = TextEditingController(
      text: cliente?.poblacion ?? '',
    );
    final observacionesController = TextEditingController(
      text: cliente?.observaciones ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 550,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  children: [
                    Icon(
                      esEdicion ? Icons.edit : Icons.person_add,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: telefonoController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nifController,
                              decoration: const InputDecoration(
                                labelText: 'NIF/CIF/NIE',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: codigoPostalController,
                              decoration: const InputDecoration(
                                labelText: 'C.P.',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: ciudadController,
                              decoration: const InputDecoration(
                                labelText: 'Ciudad',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: poblacionController,
                        decoration: const InputDecoration(
                          labelText: 'Población/Provincia',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: observacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          prefixIcon: Icon(Icons.note),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (esEdicion)
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: ctx,
                            builder: (ctx2) => AlertDialog(
                              title: const Text('Eliminar Cliente'),
                              content: Text('¿Eliminar a ${cliente.nombre}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx2),
                                  child: const Text('Cancelar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    ref
                                        .read(clientesProvider.notifier)
                                        .eliminar(cliente.id);
                                    Navigator.pop(ctx2);
                                    Navigator.pop(ctx);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                      },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (nombreController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es obligatorio'),
                            ),
                          );
                          return;
                        }

                        final nuevoCliente = Cliente(
                          id:
                              cliente?.id ??
                              'cliente_${DateTime.now().millisecondsSinceEpoch}',
                          nombre: nombreController.text.trim(),
                          telefono: telefonoController.text.trim().isNotEmpty
                              ? telefonoController.text.trim()
                              : null,
                          email: emailController.text.trim().isNotEmpty
                              ? emailController.text.trim()
                              : null,
                          nif: nifController.text.trim().isNotEmpty
                              ? nifController.text.trim()
                              : null,
                          direccion: direccionController.text.trim().isNotEmpty
                              ? direccionController.text.trim()
                              : null,
                          codigoPostal:
                              codigoPostalController.text.trim().isNotEmpty
                              ? codigoPostalController.text.trim()
                              : null,
                          ciudad: ciudadController.text.trim().isNotEmpty
                              ? ciudadController.text.trim()
                              : null,
                          poblacion: poblacionController.text.trim().isNotEmpty
                              ? poblacionController.text.trim()
                              : null,
                          observaciones:
                              observacionesController.text.trim().isNotEmpty
                              ? observacionesController.text.trim()
                              : null,
                          fechaCreacion:
                              cliente?.fechaCreacion ?? DateTime.now(),
                          totalPedidos: cliente?.totalPedidos ?? 0,
                          totalGastado: cliente?.totalGastado ?? 0,
                        );

                        if (esEdicion) {
                          ref
                              .read(clientesProvider.notifier)
                              .actualizar(nuevoCliente);
                        } else {
                          ref
                              .read(clientesProvider.notifier)
                              .agregar(nuevoCliente);
                        }
                        Navigator.pop(ctx);
                      },
                      child: Text(esEdicion ? 'Guardar' : 'Añadir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarHistorialPedidos(BuildContext context, Cliente cliente) {
    final pedidos = ref.read(pedidosProvider);
    final pedidosCliente =
        pedidos
            .where(
              (p) =>
                  p.clienteId == cliente.id && p.estado == EstadoPedido.cerrado,
            )
            .toList()
          ..sort((a, b) => b.horaApertura.compareTo(a.horaApertura));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) {
            // Estado local para el período seleccionado en el bottom sheet
            String periodoSeleccionado = 'todos';
            DateTime? fechaInicio;
            DateTime? fechaFin;

            void cambiarPeriodo(String periodo) {
              setModalState(() {
                periodoSeleccionado = periodo;
                final now = DateTime.now();
                switch (periodo) {
                  case 'hoy':
                    fechaInicio = DateTime(now.year, now.month, now.day);
                    fechaFin = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      23,
                      59,
                      59,
                    );
                    break;
                  case 'semana':
                    fechaInicio = now.subtract(const Duration(days: 7));
                    fechaFin = now;
                    break;
                  case 'mes':
                    fechaInicio = now.subtract(const Duration(days: 30));
                    fechaFin = now;
                    break;
                  case 'trimestre':
                    fechaInicio = now.subtract(const Duration(days: 90));
                    fechaFin = now;
                    break;
                  case 'ano':
                    fechaInicio = now.subtract(const Duration(days: 365));
                    fechaFin = now;
                    break;
                  case 'todos':
                    fechaInicio = null;
                    fechaFin = null;
                    break;
                }
              });
            }

            // Aplicar filtros de período
            var pedidosFiltrados = pedidosCliente;
            if (fechaInicio != null) {
              pedidosFiltrados = pedidosFiltrados
                  .where((p) => p.horaApertura.isAfter(fechaInicio!))
                  .toList();
            }
            if (fechaFin != null) {
              final finDelDia = DateTime(
                fechaFin!.year,
                fechaFin!.month,
                fechaFin!.day,
                23,
                59,
                59,
              );
              pedidosFiltrados = pedidosFiltrados
                  .where((p) => p.horaApertura.isBefore(finDelDia))
                  .toList();
            }

            Widget buildPeriodoChip(String label, String value) {
              final isSelected = periodoSeleccionado == value;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => cambiarPeriodo(value),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.zero,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                cliente.nombre.isNotEmpty
                                    ? cliente.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cliente.nombre,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${pedidosFiltrados.length} pedidos | '
                                    'Total: ${cliente.totalGastado.toStringAsFixed(2)} €',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _mostrarDialogoCliente(
                                  context,
                                  cliente: cliente,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Filtros por período
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildPeriodoChip('Hoy', 'hoy'),
                          const SizedBox(width: 8),
                          buildPeriodoChip('Semana', 'semana'),
                          const SizedBox(width: 8),
                          buildPeriodoChip('Mes', 'mes'),
                          const SizedBox(width: 8),
                          buildPeriodoChip('Trimestre', 'trimestre'),
                          const SizedBox(width: 8),
                          buildPeriodoChip('Año', 'ano'),
                          const SizedBox(width: 8),
                          buildPeriodoChip('Todos', 'todos'),
                        ],
                      ),
                    ),
                  ),
                  if (pedidosFiltrados.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay pedidos para este cliente',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: pedidosFiltrados.length,
                        itemBuilder: (context, index) {
                          final pedido = pedidosFiltrados[index];
                          return _buildPedidoCard(pedido);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPedidoCard(Pedido pedido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _mostrarDetallePedido(pedido),
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Fecha y hora
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(pedido.horaApertura).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('HH:mm').format(pedido.horaApertura),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Detalles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pedido.items.length} productos',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Badges de método de pago y cajero
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pedido.metodoPago == 'Efectivo'
                                    ? Colors.green.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                pedido.metodoPago ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: pedido.metodoPago == 'Efectivo'
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (pedido.cajeroNombre != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  pedido.cajeroNombre!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '€${pedido.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Botón imprimir
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    onPressed: () async {
                      final negocio = ref.read(negocioProvider);
                      try {
                        await PrintService.mostrarTicketPreview(
                          context: context,
                          items: pedido.items,
                          subtotal: pedido.subtotal,
                          ivaPorcentaje: negocio.ivaPorcentaje,
                          metodoPago: pedido.metodoPago ?? 'Efectivo',
                          negocio: negocio,
                          mesaNumero: pedido.mesaId,
                          cajeroNombre: pedido.cajeroNombre,
                          porcentajePropina: pedido.porcentajePropina,
                          clienteNombre: pedido.clienteNombre,
                          numeroTicket: pedido.numeroTicket,
                          fechaVenta: pedido.horaApertura,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo imprimir: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              // Vista previa de productos
              if (pedido.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: pedido.items.take(4).map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '${item.cantidad}x ${item.productoNombre}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  }).toList(),
                ),
                if (pedido.items.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${pedido.items.length - 4} más',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Toca para ver detalles',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallePedido(Pedido pedido) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalle del Pedido',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(pedido.horaApertura)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (pedido.cajeroNombre != null)
                Text(
                  'Cajero: ${pedido.cajeroNombre}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              if (pedido.mesaId.isNotEmpty)
                Text(
                  'Mesa: ${pedido.mesaId}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              Text(
                'Método de pago: ${pedido.metodoPago ?? "N/A"}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...pedido.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${item.cantidad}x ${item.productoNombre}'),
                      ),
                      Text('€${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    '€${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
