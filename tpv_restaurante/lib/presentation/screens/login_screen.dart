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
  bool _dropdownAbierto = false;
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
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
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

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: isWide
                  ? _buildLayoutHorizontal(negocio, cajerosActivos)
                  : _buildLayoutVertical(negocio, cajerosActivos),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutHorizontal(DatosNegocio negocio, List<Cajero> cajeros) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildPanelIzquierdo(negocio)),
        Expanded(flex: 3, child: _buildPanelDerecho(cajeros)),
      ],
    );
  }

  Widget _buildLayoutVertical(DatosNegocio negocio, List<Cajero> cajeros) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeader(negocio),
          const SizedBox(height: 24),
          _buildSelectorUsuarioSimple(cajeros),
          const SizedBox(height: 24),
          _buildPinPad(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildPanelIzquierdo(DatosNegocio negocio) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.restaurant, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            negocio.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sistema de Punto de Venta',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelDerecho(List<Cajero> cajeros) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Acceso al sistema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildSelectorUsuarioSimple(cajeros),
          const SizedBox(height: 32),
          _buildPinPad(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(DatosNegocio negocio) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          negocio.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorUsuarioSimple(List<Cajero> cajeros) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona tu usuario',
          style: TextStyle(
            fontSize: 16,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
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

  Widget _buildPinPad() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value *
                ((_shakeController.value * 10).toInt().isOdd ? 1 : -1),
            0,
          ),
          child: _buildPinPadContent(),
        );
      },
    );
  }

  Widget _buildPinPadContent() {
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
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _cajeroSeleccionado!.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(
          _bloqueado
              ? 'Bloqueado'
              : _cajeroSeleccionado == null
              ? 'Selecciona un usuario'
              : 'Introduce tu PIN',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _buildIndicadoresPin(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _bloqueado ? Colors.orange.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                color: _bloqueado
                    ? Colors.orange.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildTecladoNumerico(),
      ],
    );
  }

  Widget _buildIndicadoresPin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final estaLleno = index < _pinIngresado.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: estaLleno ? 20 : 18,
          height: estaLleno ? 20 : 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
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

  Widget _buildTecladoNumerico() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonSize = constraints.maxWidth > 400 ? 70.0 : 60.0;
        return Column(
          children: [
            _buildFilaTeclado(['1', '2', '3'], buttonSize),
            const SizedBox(height: 12),
            _buildFilaTeclado(['4', '5', '6'], buttonSize),
            const SizedBox(height: 12),
            _buildFilaTeclado(['7', '8', '9'], buttonSize),
            const SizedBox(height: 12),
            _buildFilaTeclado(['C', '0', '⌫'], buttonSize),
          ],
        );
      },
    );
  }

  Widget _buildFilaTeclado(List<String> teclas, double buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: teclas.map((tecla) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _buildTecla(tecla, buttonSize),
        );
      }).toList(),
    );
  }

  Widget _buildTecla(String tecla, double size) {
    final esAccion = tecla == 'C' || tecla == '⌫';
    final estaDeshabilitado = _bloqueado && !esAccion;

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
          borderRadius: BorderRadius.circular(size / 3),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: estaDeshabilitado
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                size: 24,
              )
            : Text(
                tecla,
                style: TextStyle(
                  color: estaDeshabilitado ? Colors.grey : Colors.black87,
                  fontSize: size > 65 ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
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
        const SizedBox(width: 8),
        const Text(
          'Recordarme en este dispositivo',
          style: TextStyle(color: Colors.black54, fontSize: 14),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              borderRadius: BorderRadius.circular(2),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
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
        ],
      ),
    );
  }
}
