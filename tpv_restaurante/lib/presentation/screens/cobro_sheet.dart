import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cliente.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';

class CobroSheet extends StatefulWidget {
  final double total;
  final Function(Map<String, double>, {Cliente? cliente}) onCobrar;

  const CobroSheet({super.key, required this.total, required this.onCobrar});

  @override
  State<CobroSheet> createState() => _CobroSheetState();
}

class _CobroSheetState extends State<CobroSheet> {
  String _importe = '0';
  String _metodoSeleccionado = 'Efectivo';
  Cliente? _clienteSeleccionado;

  @override
  void initState() {
    super.initState();
    _importe = widget.total.toStringAsFixed(2).replaceAll('.', ',');
  }

  double get _importeNumerico {
    if (_metodoSeleccionado == 'Tarjeta') {
      return widget.total;
    }
    return double.tryParse(_importe.replaceAll(',', '.')) ?? 0;
  }

  double get _cambio => _importeNumerico - widget.total;
  bool get _pagoCompleto => _importeNumerico >= widget.total;

  void _agregarDigito(String digito) {
    if (_metodoSeleccionado == 'Tarjeta') return;

    setState(() {
      if (digito == 'C') {
        _importe = widget.total.toStringAsFixed(2).replaceAll('.', ',');
      } else if (digito == '⌫') {
        if (_importe.length > 1) {
          _importe = _importe.substring(0, _importe.length - 1);
        } else {
          _importe = '0';
        }
      } else if (digito == ',') {
        if (!_importe.contains(',')) {
          _importe += ',';
        }
      } else {
        if (_importe == '0') {
          _importe = digito;
        } else {
          final partes = _importe.split(',');
          if (partes.length == 2 && partes[1].length >= 2) {
            return;
          }
          _importe += digito;
        }

        // Limitar a valor razonable (ej. 999999.99)
        final valor = double.tryParse(_importe.replaceAll(',', '.')) ?? 0;
        if (valor > 1000000) {
          _importe = '1000000,00';
        }
      }
    });
  }

  void _setImporte(double amount) {
    if (_metodoSeleccionado == 'Tarjeta') return;
    setState(() {
      _importe = amount.toStringAsFixed(2).replaceAll('.', ',');
    });
  }

  String _formatearImporte(String valor) {
    if (valor.isEmpty) return '0,00';
    final numericValue = double.tryParse(valor.replaceAll(',', '.')) ?? 0;
    return numericValue.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _mostrarSelectorCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SelectorClienteSheet(
        onClienteSelected: (cliente) {
          setState(() => _clienteSeleccionado = cliente);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _cobrar() {
    if (!_pagoCompleto) return;

    final metodos = <String, double>{};
    metodos[_metodoSeleccionado] = _metodoSeleccionado == 'Tarjeta'
        ? widget.total
        : _importeNumerico;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            const Text('Confirmar Cobro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  '${widget.total.toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _metodoSeleccionado == 'Efectivo' ? 'Efectivo:' : 'Tarjeta:',
                ),
                Text(
                  '${(_metodoSeleccionado == 'Tarjeta' ? widget.total : _importeNumerico).toStringAsFixed(2)} €',
                ),
              ],
            ),
            if (_metodoSeleccionado == 'Efectivo' && _cambio > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cambio:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  Text(
                    '${_cambio.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            if (_clienteSeleccionado != null) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _clienteSeleccionado!.nombre,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
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
              widget.onCobrar(metodos, cliente: _clienteSeleccionado);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'COBRAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderTotal(),
                    const SizedBox(height: 12),
                    _buildMetodoPagoSelector(),
                    const SizedBox(height: 12),
                    _buildClienteSelector(),
                    if (_metodoSeleccionado == 'Efectivo') ...[
                      const SizedBox(height: 12),
                      _buildImporteEntregado(),
                      if (_pagoCompleto && _cambio > 0) ...[
                        const SizedBox(height: 8),
                        _buildCambioDisplay(),
                      ],
                      const SizedBox(height: 12),
                      _buildKeypad(),
                    ],
                    if (_metodoSeleccionado == 'Tarjeta') ...[
                      const SizedBox(height: 12),
                      _buildTarjetaInfo(),
                    ],
                    const SizedBox(height: 12),
                    _buildBotonCobrar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTotal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL A PAGAR',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.total.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPagoSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildMetodoBoton('Efectivo', Icons.money, Colors.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetodoBoton('Tarjeta', Icons.credit_card, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildMetodoBoton(String metodo, IconData icono, Color color) {
    final isSelected = _metodoSeleccionado == metodo;
    return GestureDetector(
      onTap: () => setState(() => _metodoSeleccionado = metodo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: isSelected ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              metodo,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSelector() {
    return GestureDetector(
      onTap: _mostrarSelectorCliente,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _clienteSeleccionado != null ? Icons.person : Icons.person_add,
              color: _clienteSeleccionado != null
                  ? AppColors.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _clienteSeleccionado?.nombre ?? 'Sin cliente',
                style: TextStyle(
                  color: _clienteSeleccionado != null
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            ),
            if (_clienteSeleccionado != null)
              GestureDetector(
                onTap: () => setState(() => _clienteSeleccionado = null),
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              )
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEditarImporte() {
    if (_metodoSeleccionado == 'Tarjeta') return;
    
    final controller = TextEditingController(text: _importe.replaceAll(',', '.'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Importe'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Importe (€)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final nuevoVal = double.tryParse(val.replaceAll(',', '.'));
            if (nuevoVal != null) {
              setState(() {
                _importe = nuevoVal.toStringAsFixed(2).replaceAll('.', ',');
              });
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoVal = double.tryParse(controller.text.replaceAll(',', '.'));
              if (nuevoVal != null) {
                setState(() {
                  _importe = nuevoVal.toStringAsFixed(2).replaceAll('.', ',');
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildImporteEntregado() {
    return GestureDetector(
      onTap: _mostrarDialogoEditarImporte,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'IMPORTE ENTREGADO',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 12, color: Colors.grey.shade600),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatearImporte(_importe)} €',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _pagoCompleto ? AppColors.success : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCambioDisplay() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.euro_symbol, color: AppColors.success, size: 18),
          const SizedBox(width: 6),
          Text(
            'CAMBIO: ${_cambio.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          children: [
            _buildQuickButton(5),
            const SizedBox(width: 6),
            _buildQuickButton(10),
            const SizedBox(width: 6),
            _buildQuickButton(20),
            const SizedBox(width: 6),
            _buildQuickButton(50),
            const SizedBox(width: 6),
            _buildQuickButton(100),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [_buildTecla('1'), _buildTecla('2'), _buildTecla('3')]),
        const SizedBox(height: 6),
        Row(children: [_buildTecla('4'), _buildTecla('5'), _buildTecla('6')]),
        const SizedBox(height: 6),
        Row(children: [_buildTecla('7'), _buildTecla('8'), _buildTecla('9')]),
        const SizedBox(height: 6),
        Row(
          children: [_buildTecla(','), _buildTecla('0'), _buildTeclaAccion()],
        ),
      ],
    );
  }

  Widget _buildTarjetaInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.credit_card, size: 48, color: Colors.blue.shade700),
          const SizedBox(height: 12),
          Text(
            'PAGO EXACTO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sin cambio - ${widget.total.toStringAsFixed(2)} €',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonCobrar() {
    final canCobrar = _pagoCompleto;
    return GestureDetector(
      onTap: canCobrar ? _cobrar : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: canCobrar ? AppColors.success : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 22,
              color: canCobrar ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 10),
            Text(
              canCobrar
                  ? 'COBRAR ${widget.total.toStringAsFixed(2)} €'
                  : 'FALTAN ${(widget.total - _importeNumerico).toStringAsFixed(2)} €',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: canCobrar ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTecla(String valor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _agregarDigito(valor),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            valor == ',' ? ',' : valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaAccion() {
    return Expanded(
      child: GestureDetector(
        onTap: () => _agregarDigito('⌫'),
        onLongPress: () => _agregarDigito('C'),
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.backspace_outlined, size: 22),
        ),
      ),
    );
  }

  Widget _buildQuickButton(double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _setImporte(amount),
        child: Container(
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            '€${amount.toInt()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorClienteSheet extends ConsumerStatefulWidget {
  final Function(Cliente?) onClienteSelected;

  const _SelectorClienteSheet({required this.onClienteSelected});

  @override
  ConsumerState<_SelectorClienteSheet> createState() =>
      _SelectorClienteSheetState();
}

class _SelectorClienteSheetState extends ConsumerState<_SelectorClienteSheet> {
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
                    (c.telefono?.contains(_textoBusqueda) ?? false),
              )
              .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Seleccionar Cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _buscadorController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o teléfono...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _textoBusqueda = value),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => widget.onClienteSelected(null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Venta sin cliente'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: clientesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _textoBusqueda.isEmpty
                              ? 'No hay clientes registrados'
                              : 'No se encontraron clientes',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesFiltrados[index];
                      return GestureDetector(
                        onTap: () => widget.onClienteSelected(cliente),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (cliente.telefono != null)
                                      Text(
                                        cliente.telefono!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
