import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class MesasScreen extends ConsumerStatefulWidget {
  const MesasScreen({super.key});

  @override
  ConsumerState<MesasScreen> createState() => _MesasScreenState();
}

class _MesasScreenState extends ConsumerState<MesasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Todas', 'Libres', 'Ocupadas', 'Reservas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Mesa> _getMesasFiltradas(List<Mesa> todasMesas) {
    switch (_tabController.index) {
      case 1:
        return todasMesas.where((m) => m.estado == EstadoMesa.libre).toList();
      case 2:
        return todasMesas.where((m) => m.estado == EstadoMesa.ocupada).toList();
      case 3:
        return todasMesas
            .where((m) => m.estado == EstadoMesa.reservada)
            .toList();
      default:
        return todasMesas;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mesas = ref.watch(mesasProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(mesas),
          _buildTabBar(),
          Expanded(child: _buildMesasGrid(_getMesasFiltradas(mesas))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'agregar_mesa',
        onPressed: () => _mostrarDialogoAgregarMesas(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Mesas'),
      ),
    );
  }

  void _mostrarDialogoAgregarMesas() {
    int cantidad = 1;
    int capacidad = 4;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final mesasActuales = ref.read(mesasProvider);
          final maxNumero = mesasActuales.isEmpty
              ? 0
              : mesasActuales
                    .map((m) => m.numero)
                    .reduce((a, b) => a > b ? a : b);
          final primeraMesa = maxNumero + 1;
          final ultimaMesa = maxNumero + cantidad;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.table_restaurant, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Agregar Mesas'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cantidad == 1
                            ? 'Mesa $primeraMesa'
                            : 'Mesas $primeraMesa - $ultimaMesa',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Cantidad:'),
                    const Spacer(),
                    IconButton(
                      onPressed: cantidad > 1
                          ? () => setDialogState(() => cantidad--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => cantidad++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Capacidad:'),
                    const Spacer(),
                    IconButton(
                      onPressed: capacidad > 1
                          ? () => setDialogState(() => capacidad--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        '$capacidad pers.',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setDialogState(() => capacidad++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  for (int i = 0; i < cantidad; i++) {
                    final nuevoNumero = maxNumero + 1 + i;
                    final nuevaMesa = Mesa(
                      id: 'mesa_$nuevoNumero',
                      numero: nuevoNumero,
                      capacidad: capacidad,
                      estado: EstadoMesa.libre,
                    );
                    ref.read(mesasProvider.notifier).agregar(nuevaMesa);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: [
          Tab(text: 'Todas (${ref.watch(mesasProvider).length})'),
          Tab(
            text:
                'Libres (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.libre).length})',
          ),
          Tab(
            text:
                'Ocupadas (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.ocupada).length})',
          ),
          Tab(
            text:
                'Reservas (${ref.watch(mesasProvider).where((m) => m.estado == EstadoMesa.reservada).length})',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<Mesa> mesas) {
    final libres = mesas.where((m) => m.estado == EstadoMesa.libre).length;
    final ocupadas = mesas.where((m) => m.estado == EstadoMesa.ocupada).length;
    final reservadas = mesas
        .where((m) => m.estado == EstadoMesa.reservada)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.table_restaurant,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mesas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  '${mesas.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBadge(libres, 'Libres', AppColors.success),
              const SizedBox(width: 8),
              _buildStatBadge(ocupadas, 'Ocupadas', AppColors.warning),
              const SizedBox(width: 8),
              _buildStatBadge(reservadas, 'Reservas', AppColors.mesaReservada),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesasGrid(List<Mesa> mesas) {
    if (mesas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_restaurant, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay mesas',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemCount: mesas.length,
      itemBuilder: (context, index) => _buildMesaCard(mesas[index]),
    );
  }

  Widget _buildMesaCard(Mesa mesa) {
    final estadoData = _getEstadoData(mesa.estado);
    final pedidoActual = mesa.pedidoActualId != null
        ? ref
              .read(pedidosProvider)
              .where((p) => p.id == mesa.pedidoActualId)
              .firstOrNull
        : null;
    final totalPedido =
        pedidoActual?.items.fold<double>(
          0,
          (sum, item) => sum + item.subtotal,
        ) ??
        0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: () => _mostrarOpcionesMesa(context, mesa),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [estadoData.color.withValues(alpha: 0.1), Colors.white],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoData.color.withValues(alpha: 0.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estadoData.icono,
                          size: 10,
                          color: estadoData.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          estadoData.texto,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: estadoData.color,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 9,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${mesa.capacidad}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        size: 28,
                        color: estadoData.color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (mesa.estado == EstadoMesa.ocupada &&
                          totalPedido > 0) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            '${totalPedido.toStringAsFixed(2)} €',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _EstadoData _getEstadoData(EstadoMesa estado) {
    switch (estado) {
      case EstadoMesa.libre:
        return _EstadoData(AppColors.success, 'Libre', Icons.check_circle);
      case EstadoMesa.ocupada:
        return _EstadoData(AppColors.warning, 'Ocupada', Icons.restaurant);
      case EstadoMesa.reservada:
        return _EstadoData(AppColors.mesaReservada, 'Reservada', Icons.event);
      case EstadoMesa.necesitaAtencion:
        return _EstadoData(
          AppColors.error,
          'Atención',
          Icons.notification_important,
        );
    }
  }

  void _mostrarOpcionesMesa(BuildContext context, Mesa mesa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getEstadoData(
                        mesa.estado,
                      ).color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(
                      Icons.table_restaurant,
                      color: _getEstadoData(mesa.estado).color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${mesa.capacidad} personas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (mesa.estado == EstadoMesa.libre) ...[
              _buildOpcion(Icons.edit, 'Editar', AppColors.primary, () {
                Navigator.pop(context);
                _editarMesa(context, mesa);
              }),
              _buildOpcion(
                Icons.event_available,
                'Reservar',
                AppColors.mesaReservada,
                () {
                  Navigator.pop(context);
                  _mostrarDialogoReserva(mesa);
                },
              ),
            ],
            if (mesa.estado == EstadoMesa.ocupada) ...[
              _buildOpcion(Icons.edit, 'Editar', AppColors.primary, () {
                Navigator.pop(context);
                _editarMesa(context, mesa);
              }),
              _buildOpcion(Icons.payment, 'Cobrar', AppColors.success, () {
                Navigator.pop(context);
                _cobrarMesa(mesa);
              }),
              _buildOpcion(
                Icons.remove_circle,
                'Quitar',
                AppColors.warning,
                () {
                  Navigator.pop(context);
                  _cancelarMesa(mesa);
                },
              ),
            ],
            if (mesa.estado == EstadoMesa.reservada) ...[
              _buildOpcion(Icons.edit, 'Editar', AppColors.primary, () {
                Navigator.pop(context);
                _editarMesa(context, mesa);
              }),
              _buildOpcion(
                Icons.check_circle,
                'Activar',
                AppColors.success,
                () {
                  Navigator.pop(context);
                  _abrirMesa(mesa);
                },
              ),
            ],
            if (mesa.estado == EstadoMesa.necesitaAtencion) ...[
              _buildOpcion(Icons.edit, 'Editar', AppColors.primary, () {
                Navigator.pop(context);
                _editarMesa(context, mesa);
              }),
              _buildOpcion(Icons.check, 'Atender', AppColors.primary, () {
                Navigator.pop(context);
                ref.read(mesasProvider.notifier).liberar(mesa.id);
              }),
            ],
            _buildOpcion(Icons.delete, 'Eliminar Mesa', AppColors.error, () {
              Navigator.pop(context);
              _eliminarMesa(mesa);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcion(
    IconData icono,
    String texto,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.zero,
        ),
        child: Icon(icono, color: color, size: 20),
      ),
      title: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }

  void _abrirMesa(Mesa mesa) async {
    final cajeroActual = ref.read(cajeroActualProvider);
    final cajaActual = ref.read(cajaProvider);
    final pedidoId = await ref
        .read(pedidosProvider.notifier)
        .crear(
          mesa.id,
          cajeroId: cajeroActual?.id,
          cajeroNombre: cajeroActual?.nombre,
          cajaId: cajaActual?.id,
        );
    await ref.read(mesasProvider.notifier).ocupar(mesa.id, pedidoId);
  }

  void _editarMesa(BuildContext context, Mesa mesa) {
    final numeroController = TextEditingController(
      text: mesa.numero.toString(),
    );
    final nombreController = TextEditingController(text: mesa.nombre ?? '');
    final capacidadController = TextEditingController(
      text: mesa.capacidad.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar ${mesa.nombreMostrar}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numeroController,
              decoration: const InputDecoration(
                labelText: 'Número',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre (opcional)',
                hintText: 'Ej: Terraza, VIP...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacidadController,
              decoration: const InputDecoration(
                labelText: 'Capacidad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final numero = int.tryParse(numeroController.text);
              final capacidad = int.tryParse(capacidadController.text);
              final nombre = nombreController.text.trim();
              if (numero != null && capacidad != null) {
                await ref
                    .read(mesasProvider.notifier)
                    .actualizarMesa(
                      mesa.id,
                      numero: numero,
                      nombre: nombre.isEmpty ? null : nombre,
                      capacidad: capacidad,
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoReserva(Mesa mesa) {
    DateTime fechaReserva = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.event_available, color: AppColors.mesaReservada),
              const SizedBox(width: 12),
              Text('Reservar ${mesa.nombreMostrar}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  '${fechaReserva.day}/${fechaReserva.month}/${fechaReserva.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: fechaReserva,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (fecha != null) {
                    setDialogState(() {
                      fechaReserva = DateTime(
                        fecha.year,
                        fecha.month,
                        fecha.day,
                        fechaReserva.hour,
                        fechaReserva.minute,
                      );
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${fechaReserva.hour.toString().padLeft(2, '0')}:${fechaReserva.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(fechaReserva),
                  );
                  if (hora != null) {
                    setDialogState(() {
                      fechaReserva = DateTime(
                        fechaReserva.year,
                        fechaReserva.month,
                        fechaReserva.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(mesasProvider.notifier)
                    .actualizarMesa(mesa.id, fechaReserva: fechaReserva);
                ref.read(mesasProvider.notifier).marcarReservada(mesa.id);
                Navigator.pop(ctx);
              },
              child: const Text('Reservar'),
            ),
          ],
        ),
      ),
    );
  }

  void _cobrarMesa(Mesa mesa) async {
    final pedido = mesa.pedidoActualId != null
        ? ref
              .read(pedidosProvider)
              .where((p) => p.id == mesa.pedidoActualId)
              .firstOrNull
        : null;

    if (pedido == null) return;

    ref.read(mesaVentaSeleccionadaProvider.notifier).state = mesa.id;
    ref.read(indiceNavegacionProvider.notifier).state = 0;
  }

  void _cancelarMesa(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pedido'),
        content: const Text('¿Cancelar el pedido y liberar la mesa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (mesa.pedidoActualId != null) {
                final pedido = ref
                    .read(pedidosProvider)
                    .where((p) => p.id == mesa.pedidoActualId)
                    .firstOrNull;
                if (pedido != null) {
                  final cajaActual = ref.read(cajaProvider);
                  await ref
                      .read(pedidosProvider.notifier)
                      .cerrar(pedido.id, 'Cancelado', cajaId: cajaActual?.id);
                }
              }
              await ref.read(mesasProvider.notifier).liberar(mesa.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _eliminarMesa(Mesa mesa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Mesa'),
        content: Text('¿Eliminar Mesa ${mesa.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(mesasProvider.notifier).eliminar(mesa.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _EstadoData {
  final Color color;
  final String texto;
  final IconData icono;

  _EstadoData(this.color, this.texto, this.icono);
}

class _CobroMesaSheet extends StatefulWidget {
  final double total;
  final int mesaNumero;
  final Function(Map<String, double>) onCobrar;

  const _CobroMesaSheet({
    required this.total,
    required this.mesaNumero,
    required this.onCobrar,
  });

  @override
  State<_CobroMesaSheet> createState() => _CobroMesaSheetState();
}

class _CobroMesaSheetState extends State<_CobroMesaSheet> {
  final _efectivoController = TextEditingController();
  final _tarjetaController = TextEditingController();
  bool _dividirPago = false;

  @override
  void initState() {
    super.initState();
    _efectivoController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _efectivoController.dispose();
    _tarjetaController.dispose();
    super.dispose();
  }

  double get _efectivo => double.tryParse(_efectivoController.text) ?? 0;
  double get _tarjeta => double.tryParse(_tarjetaController.text) ?? 0;
  double get _totalPagado => _efectivo + _tarjeta;
  double get _cambio => _totalPagado - widget.total;
  double get _faltaPagar => widget.total - _totalPagado;
  bool get _pagoCompleto => _totalPagado >= widget.total;

  void _cobrar() {
    if (!_pagoCompleto) return;

    final metodos = <String, double>{};
    if (_efectivo > 0) metodos['Efectivo'] = _efectivo;
    if (_tarjeta > 0) metodos['Tarjeta'] = _tarjeta;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 12),
            Text('Confirmar Cobro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mesa ${widget.mesaNumero}'),
            Text('Total: ${widget.total.toStringAsFixed(2)} €'),
            Text('Pagado: ${_totalPagado.toStringAsFixed(2)} €'),
            if (_cambio > 0)
              Text(
                'Cambio: ${_cambio.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 18,
                ),
              ),
            const SizedBox(height: 8),
            const Text('¿Confirmar el cobro?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onCobrar(metodos);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success,
                    AppColors.success.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL A COBRAR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.total.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Mesa ${widget.mesaNumero}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _dividirPago = false;
                      _efectivoController.text = widget.total.toStringAsFixed(
                        2,
                      );
                      _tarjetaController.clear();
                    }),
                    icon: Icon(
                      _dividirPago
                          ? Icons.radio_button_unchecked
                          : Icons.check_circle,
                      size: 20,
                    ),
                    label: const Text('Pago Completo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: !_dividirPago
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _dividirPago = true;
                      _efectivoController.text = '';
                      _tarjetaController.text = '';
                    }),
                    icon: Icon(
                      _dividirPago
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                    ),
                    label: const Text('Dividir'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: _dividirPago
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_dividirPago)
              _buildImporteField(
                controller: _efectivoController,
                label: 'Importe recibido (Efectivo)',
                color: AppColors.success,
              )
            else ...[
              _buildImporteField(
                controller: _efectivoController,
                label: 'Efectivo',
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _buildImporteField(
                controller: _tarjetaController,
                label: 'Tarjeta',
                color: AppColors.primary,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.zero,
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'Total:',
                    '${widget.total.toStringAsFixed(2)} €',
                  ),
                  if (_dividirPago || _efectivo > 0)
                    _buildInfoRow(
                      'Efectivo:',
                      '${_efectivo.toStringAsFixed(2)} €',
                    ),
                  if (_tarjeta > 0)
                    _buildInfoRow(
                      'Tarjeta:',
                      '${_tarjeta.toStringAsFixed(2)} €',
                    ),
                  const Divider(),
                  _buildInfoRow(
                    'Pagado:',
                    '${_totalPagado.toStringAsFixed(2)} €',
                    bold: true,
                  ),
                  if (_faltaPagar > 0)
                    _buildInfoRow(
                      'Falta:',
                      '${_faltaPagar.toStringAsFixed(2)} €',
                      color: AppColors.error,
                    )
                  else
                    _buildInfoRow(
                      'Cambio:',
                      '${_cambio.toStringAsFixed(2)} €',
                      color: AppColors.success,
                      bold: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _pagoCompleto ? _cobrar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _pagoCompleto
                          ? 'COBRAR'
                          : 'FALTAN ${_faltaPagar.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImporteField({
    required TextEditingController controller,
    required String label,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '€ ',
        prefixStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
