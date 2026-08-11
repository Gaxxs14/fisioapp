import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class InactivityTracker extends ConsumerStatefulWidget {
  final Widget child;

  const InactivityTracker({super.key, required this.child});

  @override
  ConsumerState<InactivityTracker> createState() => _InactivityTrackerState();
}

class _InactivityTrackerState extends ConsumerState<InactivityTracker> {
  Timer? _timer;
  
  // 3 minutos de inactividad
  static const Duration _inactivityDuration = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _cancelTimer();
    
    // Solo rastrear si el usuario ya inició sesión
    final authState = ref.read(authControllerProvider);
    if (authState.user != null) {
      _timer = Timer(_inactivityDuration, _handleInactivityTimeout);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleInactivityTimeout() {
    // Cerrar sesión por inactividad
    ref.read(authControllerProvider.notifier).signOut();
    
    // Mostrar un mensaje en pantalla
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu sesión ha expirado tras 3 minutos de inactividad por seguridad.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  // Se ejecuta con cualquier interacción en pantalla
  void _onUserInteraction(PointerEvent event) {
    _startTimer();
  }

  @override
  Widget build(BuildContext childContext) {
    // Escuchar el estado de autenticación. Si el usuario se desloguea, cancelamos el timer.
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        _cancelTimer();
      } else {
        _startTimer();
      }
    });

    return Listener(
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      onPointerUp: _onUserInteraction,
      child: widget.child,
    );
  }
}
