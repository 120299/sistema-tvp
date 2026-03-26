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
    if (_metodoSeleccionado == 'Tarjeta') return widget.total;
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
        if (_importe.isNotEmpty && !_importe.contains(',')) {
          _importe += ',';
        }
      } else {
        if (_importe == '0' || _importe == '0,00') {
          _importe = digito;
        } else {
          final partes = _importe.split(',');
          if (partes.length == 2 && partes[1].length >= 2) return;
          _importe += digito;
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
    widget.onCobrar(metodos, cliente: _clienteSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final compact = screenH < 700;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top row: Total + Cliente
                  Row(
                    children: [
                      Expanded(child: _buildHeaderTotal(compact)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildClienteSelector()),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 8),

                  // Método de pago
                  _buildMetodoPagoSelector(),
                  SizedBox(height: compact ? 6 : 8),

                  if (_metodoSeleccionado == 'Efectivo') ...[
                    _buildImporteEntregado(compact),
                    if (_pagoCompleto && _cambio > 0) ...[
                      const SizedBox(height: 4),
                      _buildCambioDisplay(),
                    ],
                    SizedBox(height: compact ? 4 : 6),
                    // Quick amounts
                    _buildQuickAmounts(),
                    SizedBox(height: compact ? 4 : 6),
                    // Numeric keypad
                    _buildKeypad(compact),
                  ],

                  if (_metodoSeleccionado == 'Tarjeta') ...[
                    SizedBox(height: compact ? 4 : 8),
                    _buildTarjetaInfo(),
                  ],

                  SizedBox(height: compact ? 8 : 10),
                  _buildBotonCobrar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTotal(bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TOTAL',
            style: TextStyle(
              fontSize: compact ? 8 : 9,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${widget.total.toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: compact ? 16 : 18,
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
        const SizedBox(width: 8),
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
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              metodo,
              style: TextStyle(
                fontSize: 11,
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
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            Icon(
              _clienteSeleccionado != null ? Icons.person : Icons.person_add,
              color: _clienteSeleccionado != null
                  ? AppColors.primary
                  : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _clienteSeleccionado?.nombre.split(' ').first ?? 'Cliente',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: _clienteSeleccionado != null
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImporteEntregado(bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Text(
            'IMPORTE ENTREGADO',
            style: TextStyle(
              fontSize: compact ? 7 : 8,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
          Text(
            '${_importe == "0" ? "0,00" : _importe} €',
            style: TextStyle(
              fontSize: compact ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: _pagoCompleto ? AppColors.success : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCambioDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'CAMBIO:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_cambio.toStringAsFixed(2)} €',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmounts() {
    final amounts = [5.0, 10.0, 20.0, 50.0];
    return Row(
      children: amounts.map((amount) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _setImporte(amount),
            child: Container(
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.07),
                border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                borderRadius: BorderRadius.zero,
              ),
              alignment: Alignment.center,
              child: Text(
                '${amount.toInt()}€',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypad(bool compact) {
    final teclaHeight = compact ? 34.0 : 40.0;
    return Column(
      children: [
        Row(
          children: [
            _buildTecla('1', teclaHeight),
            _buildTecla('2', teclaHeight),
            _buildTecla('3', teclaHeight),
          ],
        ),
        SizedBox(height: compact ? 3 : 4),
        Row(
          children: [
            _buildTecla('4', teclaHeight),
            _buildTecla('5', teclaHeight),
            _buildTecla('6', teclaHeight),
          ],
        ),
        SizedBox(height: compact ? 3 : 4),
        Row(
          children: [
            _buildTecla('7', teclaHeight),
            _buildTecla('8', teclaHeight),
            _buildTecla('9', teclaHeight),
          ],
        ),
        SizedBox(height: compact ? 3 : 4),
        Row(
          children: [
            _buildTecla(',', teclaHeight),
            _buildTecla('0', teclaHeight),
            _buildTeclaAccion(teclaHeight),
          ],
        ),
      ],
    );
  }

  Widget _buildTarjetaInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 28, color: Colors.blue.shade700),
          const SizedBox(height: 6),
          Text(
            'PAGO CON TARJETA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          Text(
            'Cobro exacto de ${widget.total.toStringAsFixed(2)} €',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
        height: 44,
        decoration: BoxDecoration(
          color: canCobrar ? AppColors.success : Colors.grey.shade300,
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: canCobrar ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              canCobrar
                  ? 'CONFIRMAR COBRO  ${widget.total.toStringAsFixed(2)} €'
                  : 'FALTA DINERO',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: canCobrar ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTecla(String valor, double height) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _agregarDigito(valor),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            valor,
            style: TextStyle(
              fontSize: height < 38 ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaAccion(double height) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _agregarDigito('⌫'),
        onLongPress: () => _agregarDigito('C'),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.backspace_outlined, size: height < 38 ? 16 : 18),
        ),
      ),
    );
  }
}

// ─── Selector de Cliente ───────────────────────────────────────────────────────

class _SelectorClienteSheet extends ConsumerWidget {
  final Function(Cliente) onClienteSelected;

  const _SelectorClienteSheet({required this.onClienteSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientes = ref.watch(clientesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SELECCIONAR CLIENTE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: clientes.isEmpty
                ? const Center(child: Text('No hay clientes registrados'))
                : ListView.separated(
                    itemCount: clientes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cliente = clientes[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person, size: 20),
                        title: Text(
                          cliente.nombre,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: cliente.telefono != null
                            ? Text(
                                cliente.telefono!,
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                        onTap: () => onClienteSelected(cliente),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
