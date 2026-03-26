import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  String _pinIngresado = '';
  Cajero? _cajeroSeleccionado;
  String? _error;
  int _intentosFallidos = 0;
  bool _bloqueado = false;
  bool _recordarme = true;
  bool _cargando = true;
  final TextEditingController _busquedaController = TextEditingController();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _verificarSesionGuardada();
  }

  Future<void> _verificarSesionGuardada() async {
    if (!_recordarme) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final session = await _cargarSesion();
      if (session != null && mounted) {
        final cajeros = ref.read(cajerosProvider);
        Cajero? cajero;
        try {
          cajero = cajeros.firstWhere((c) => c.id == session['cajeroId']);
        } catch (_) {
          cajero = cajeros.isNotEmpty ? cajeros.first : null;
        }

        if (cajero != null && cajero.activo) {
          ref.read(cajeroActualProvider.notifier).state = cajero;
          widget.onLoginSuccess();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error verificando sesión: $e');
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  Future<Map<String, dynamic>?> _cargarSesion() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tpv_session.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error cargando sesión: $e');
    }
    return null;
  }

  Future<void> _guardarSesion() async {
    if (_cajeroSeleccionado == null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tpv_session.json');
      final session = {
        'cajeroId': _cajeroSeleccionado!.id,
        'cajeroNombre': _cajeroSeleccionado!.nombre,
        'isAdmin': _cajeroSeleccionado!.isAdministrador,
        'fechaLogin': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(jsonEncode(session));
    } catch (e) {
      debugPrint('Error guardando sesión: $e');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  void _agregarDigito(String digito) {
    if (_bloqueado || _pinIngresado.length >= 4) return;
    if (_cajeroSeleccionado == null) {
      _mostrarError('Selecciona un usuario');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      _pinIngresado += digito;
      _error = null;
    });

    if (_pinIngresado.length == 4) {
      _verificarPin();
    }
  }

  void _borrarDigito() {
    if (_pinIngresado.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pinIngresado = _pinIngresado.substring(0, _pinIngresado.length - 1);
      _error = null;
    });
  }

  void _verificarPin() {
    if (_cajeroSeleccionado == null) {
      _mostrarError('Selecciona un usuario');
      return;
    }

    final pinRequerido = _cajeroSeleccionado!.pin;

    if (pinRequerido == null || pinRequerido.isEmpty) {
      _loginDirecto();
    } else if (_pinIngresado == pinRequerido) {
      _loginDirecto();
    } else {
      _intentosFallidos++;
      if (_intentosFallidos >= 3) {
        _bloquear();
      } else {
        _mostrarError('PIN incorrecto. Intento $_intentosFallidos/3');
      }
    }
  }

  void _mostrarError(String mensaje) {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    setState(() {
      _error = mensaje;
      _pinIngresado = '';
    });
  }

  void _bloquear() {
    setState(() {
      _bloqueado = true;
      _error = 'Demasiados intentos. Espera 30 segundos.';
    });
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _bloqueado = false;
          _intentosFallidos = 0;
          _error = null;
        });
      }
    });
  }

  Future<void> _loginDirecto() async {
    HapticFeedback.mediumImpact();
    ref.read(cajeroActualProvider.notifier).state = _cajeroSeleccionado;
    if (_recordarme) await _guardarSesion();
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    final negocio = ref.watch(negocioProvider);
    final cajeros = ref.watch(cajerosProvider);
    final cajerosActivos = cajeros.where((c) => c.activo).toList();
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenH < 700;
    final isWide = screenW > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          ),
        ),
        child: SafeArea(
          child: isWide
              ? _buildLayoutHorizontal(
                  negocio,
                  cajerosActivos,
                  isCompact: isCompact,
                )
              : _buildLayoutVertical(
                  negocio,
                  cajerosActivos,
                  isCompact: isCompact,
                ),
        ),
      ),
    );
  }

  Widget _buildLayoutHorizontal(
    DatosNegocio negocio,
    List<Cajero> cajeros, {
    bool isCompact = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildPanelIzquierdo(negocio, isCompact: isCompact),
        ),
        Expanded(
          flex: 3,
          child: _buildPanelDerecho(cajeros, isCompact: isCompact),
        ),
      ],
    );
  }

  Widget _buildLayoutVertical(
    DatosNegocio negocio,
    List<Cajero> cajeros, {
    bool isCompact = false,
  }) {
    final screenW = MediaQuery.of(context).size.width;
    final isNarrow = screenW < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 8 : 16),
      child: Column(
        children: [
          _buildHeader(negocio, isCompact: isCompact),
          SizedBox(height: isCompact ? 12 : 24),
          _buildSelectorUsuarioSimple(cajeros, isCompact: isCompact),
          SizedBox(height: isCompact ? 12 : 24),
          _buildPinPad(isCompact: isCompact, isNarrow: isNarrow),
          SizedBox(height: isCompact ? 8 : 24),
          _buildFooter(isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildPanelIzquierdo(DatosNegocio negocio, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.rectangle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.restaurant,
              size: isCompact ? 48 : 64,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 24),
          Text(
            negocio.nombre,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 20 : 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isCompact ? 6 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 16,
              vertical: isCompact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              'Sistema de Punto de Venta',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isCompact ? 11 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelDerecho(List<Cajero> cajeros, {bool isCompact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Acceso al sistema',
            style: TextStyle(
              fontSize: isCompact ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 24),
          _buildSelectorUsuarioSimple(cajeros, isCompact: isCompact),
          SizedBox(height: isCompact ? 16 : 32),
          _buildPinPad(isCompact: isCompact, isNarrow: false),
          SizedBox(height: isCompact ? 12 : 24),
          _buildFooter(isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildHeader(DatosNegocio negocio, {bool isCompact = false}) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 12 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.rectangle,
          ),
          child: Icon(
            Icons.restaurant,
            size: isCompact ? 32 : 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        Text(
          negocio.nombre,
          style: TextStyle(
            color: Colors.white,
            fontSize: isCompact ? 18 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorUsuarioSimple(
    List<Cajero> cajeros, {
    bool isCompact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona tu usuario',
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _mostrarSelectorUsuario(cajeros),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.rectangle,
                  ),
                  child: Icon(
                    _cajeroSeleccionado != null
                        ? (_cajeroSeleccionado!.isAdministrador
                              ? Icons.admin_panel_settings
                              : Icons.person)
                        : Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cajeroSeleccionado?.nombre ?? 'Seleccionar usuario...',
                        style: TextStyle(
                          color: _cajeroSeleccionado != null
                              ? Colors.black87
                              : Colors.grey,
                          fontSize: 16,
                          fontWeight: _cajeroSeleccionado != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (_cajeroSeleccionado != null)
                        Text(
                          _cajeroSeleccionado!.isAdministrador
                              ? 'Administrador'
                              : 'Cajero',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarSelectorUsuario(List<Cajero> cajeros) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UsuarioSelectorSheet(
        cajeros: cajeros,
        cajeroSeleccionado: _cajeroSeleccionado,
        onSelected: (cajero) {
          setState(() {
            _cajeroSeleccionado = cajero;
            _pinIngresado = '';
            _error = null;
          });
          Navigator.pop(ctx);

          if (cajero.pin == null || cajero.pin!.isEmpty) {
            _loginDirecto();
          }
        },
      ),
    );
  }

  Widget _buildPinPad({bool isCompact = false, bool isNarrow = false}) {
    final buttonSize = isNarrow ? 50.0 : (isCompact ? 55.0 : 70.0);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value *
                ((_shakeController.value * 10).toInt().isOdd ? 1 : -1),
            0,
          ),
          child: _buildPinPadContent(
            isCompact: isCompact,
            buttonSize: buttonSize,
          ),
        );
      },
    );
  }

  Widget _buildPinPadContent({bool isCompact = false, double buttonSize = 70}) {
    return Column(
      children: [
        if (_cajeroSeleccionado != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _cajeroSeleccionado!.isAdministrador
                    ? Icons.admin_panel_settings
                    : Icons.person,
                color: AppColors.primary,
                size: isCompact ? 16 : 20,
              ),
              SizedBox(width: isCompact ? 4 : 8),
              Text(
                _cajeroSeleccionado!.nombre,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 16),
        ],
        Text(
          _bloqueado
              ? 'Bloqueado'
              : _cajeroSeleccionado == null
              ? 'Selecciona un usuario'
              : 'Introduce tu PIN',
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: isCompact ? 8 : 16),
        _buildIndicadoresPin(isCompact: isCompact),
        if (_error != null) ...[
          SizedBox(height: isCompact ? 6 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 16,
              vertical: isCompact ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: _bloqueado ? Colors.orange.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              _error!,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: _bloqueado
                    ? Colors.orange.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),
        ],
        SizedBox(height: isCompact ? 12 : 24),
        _buildTecladoNumerico(buttonSize: buttonSize, isCompact: isCompact),
      ],
    );
  }

  Widget _buildIndicadoresPin({bool isCompact = false}) {
    final size = isCompact ? 14.0 : 18.0;
    final margin = isCompact ? 6.0 : 10.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final estaLleno = index < _pinIngresado.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.symmetric(horizontal: margin),
          width: estaLleno ? size + 2 : size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: estaLleno ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: _error != null ? Colors.red : AppColors.primary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTecladoNumerico({
    double buttonSize = 70,
    bool isCompact = false,
  }) {
    final spacing = isCompact ? 6.0 : 12.0;
    return Column(
      children: [
        _buildFilaTeclado(['1', '2', '3'], buttonSize, isCompact: isCompact),
        SizedBox(height: spacing),
        _buildFilaTeclado(['4', '5', '6'], buttonSize, isCompact: isCompact),
        SizedBox(height: spacing),
        _buildFilaTeclado(['7', '8', '9'], buttonSize, isCompact: isCompact),
        SizedBox(height: spacing),
        _buildFilaTeclado(['C', '0', '⌫'], buttonSize, isCompact: isCompact),
      ],
    );
  }

  Widget _buildFilaTeclado(
    List<String> teclas,
    double buttonSize, {
    bool isCompact = false,
  }) {
    final padding = isCompact ? 4.0 : 8.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: teclas.map((tecla) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _buildTecla(tecla, buttonSize, isCompact: isCompact),
        );
      }).toList(),
    );
  }

  Widget _buildTecla(String tecla, double size, {bool isCompact = false}) {
    final esAccion = tecla == 'C' || tecla == '⌫';
    final estaDeshabilitado = _bloqueado && !esAccion;
    final iconSize = isCompact ? 16.0 : 20.0;
    final fontSize = isCompact ? 14.0 : 18.0;

    return GestureDetector(
      onTap: estaDeshabilitado
          ? null
          : () {
              if (tecla == 'C') {
                setState(() {
                  _pinIngresado = '';
                  _error = null;
                });
              } else if (tecla == '⌫') {
                _borrarDigito();
              } else {
                _agregarDigito(tecla);
              }
            },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: estaDeshabilitado
              ? Colors.grey.shade200
              : esAccion
              ? Colors.grey.shade100
              : Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: estaDeshabilitado
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: esAccion
            ? Icon(
                tecla == 'C' ? Icons.close : Icons.backspace_outlined,
                color: estaDeshabilitado ? Colors.grey : Colors.grey.shade700,
                size: iconSize,
              )
            : Text(
                tecla,
                style: TextStyle(
                  color: estaDeshabilitado ? Colors.grey : Colors.black87,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter({bool isCompact = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _recordarme,
            onChanged: (v) => setState(() => _recordarme = v ?? false),
            activeColor: AppColors.primary,
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        Text(
          'Recordarme',
          style: TextStyle(
            color: Colors.black54,
            fontSize: isCompact ? 12 : 14,
          ),
        ),
      ],
    );
  }
}

class _UsuarioSelectorSheet extends StatefulWidget {
  final List<Cajero> cajeros;
  final Cajero? cajeroSeleccionado;
  final ValueChanged<Cajero> onSelected;

  const _UsuarioSelectorSheet({
    required this.cajeros,
    required this.cajeroSeleccionado,
    required this.onSelected,
  });

  @override
  State<_UsuarioSelectorSheet> createState() => _UsuarioSelectorSheetState();
}

class _UsuarioSelectorSheetState extends State<_UsuarioSelectorSheet> {
  final TextEditingController _busquedaController = TextEditingController();
  late List<Cajero> _cajerosFiltrados;

  @override
  void initState() {
    super.initState();
    _cajerosFiltrados = widget.cajeros;
    _busquedaController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _filtrar() {
    final texto = _busquedaController.text.toLowerCase();
    setState(() {
      if (texto.isEmpty) {
        _cajerosFiltrados = widget.cajeros;
      } else {
        _cajerosFiltrados = widget.cajeros
            .where((c) => c.nombre.toLowerCase().contains(texto))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar Usuario',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cajerosFiltrados.length,
              itemBuilder: (context, index) {
                final cajero = _cajerosFiltrados[index];
                final esSeleccionado =
                    widget.cajeroSeleccionado?.id == cajero.id;

                return ListTile(
                  onTap: () => widget.onSelected(cajero),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: esSeleccionado
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.grey.shade100,
                      shape: BoxShape.rectangle,
                    ),
                    child: Icon(
                      cajero.isAdministrador
                          ? Icons.admin_panel_settings
                          : Icons.person,
                      color: esSeleccionado
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(
                    cajero.nombre,
                    style: TextStyle(
                      fontWeight: esSeleccionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: esSeleccionado
                          ? AppColors.primary
                          : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    cajero.isAdministrador ? 'Administrador' : 'Cajero',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: esSeleccionado
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                );
              },
            ),
          ),
          if (_cajerosFiltrados.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No se encontraron usuarios',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Salir'),
                    content: const Text('¿Salir de la aplicación?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
                if (confirmar == true) {
                  exit(0);
                }
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Salir'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
