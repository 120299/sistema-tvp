import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';

class MesaCard extends StatelessWidget {
  final Mesa mesa;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MesaCard({
    super.key,
    required this.mesa,
    required this.onTap,
    this.onLongPress,
  });

  Color get _colorEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return AppColors.mesaLibre;
      case EstadoMesa.ocupada:
        return AppColors.mesaOcupada;
      case EstadoMesa.reservada:
        return AppColors.mesaReservada;
      case EstadoMesa.necesitaAtencion:
        return AppColors.mesaAtencion;
    }
  }

  IconData get _iconoEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return Icons.check_circle;
      case EstadoMesa.ocupada:
        return Icons.restaurant;
      case EstadoMesa.reservada:
        return Icons.schedule;
      case EstadoMesa.necesitaAtencion:
        return Icons.warning;
    }
  }

  String get _textoEstado {
    switch (mesa.estado) {
      case EstadoMesa.libre:
        return 'Libre';
      case EstadoMesa.ocupada:
        return _formatearTiempo(mesa.tiempoTranscurrido);
      case EstadoMesa.reservada:
        return 'Reservada';
      case EstadoMesa.necesitaAtencion:
        return 'Atención';
    }
  }

  String _formatearTiempo(Duration? duracion) {
    if (duracion == null) return '';
    final minutos = duracion.inMinutes;
    if (minutos < 60) return '${minutos}m';
    final horas = duracion.inHours;
    final mins = minutos % 60;
    return '${horas}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _colorEstado,
            width: mesa.estado == EstadoMesa.necesitaAtencion ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _colorEstado.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_iconoEstado, color: _colorEstado, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mesa ${mesa.numero}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${mesa.capacidad} personas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _colorEstado,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _textoEstado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
