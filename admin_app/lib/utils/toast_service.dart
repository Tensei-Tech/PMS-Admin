import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class AdminToast {
  AdminToast._();

  static void showSuccess(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'SUCCESS',
      type: ToastType.success,
      duration: duration,
    );
  }

  static void showError(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'ERROR',
      type: ToastType.error,
      duration: duration,
    );
  }

  static void showWarning(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'WARNING',
      type: ToastType.warning,
      duration: duration,
    );
  }

  static void showInfo(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title ?? 'NOTICE',
      type: ToastType.info,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    required String title,
    required ToastType type,
    Duration? duration,
  }) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _TopRightToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration ?? const Duration(seconds: 4),
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlayState.insert(entry);
  }
}

class _TopRightToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopRightToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopRightToastWidget> createState() => _TopRightToastWidgetState();
}

class _TopRightToastWidgetState extends State<_TopRightToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0), // Slide in from right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getToastColors(widget.type);

    return Positioned(
      top: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 380,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Sleek Dark Slate
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadowColor.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accentColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(colors.icon, color: colors.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.title.toUpperCase(),
                              style: TextStyle(
                                color: colors.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFFF8FAFC),
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _dismissWithAnimation,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastColors _getToastColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastColors(
          accentColor: const Color(0xFF10B981), // Emerald Green
          borderColor: const Color(0xFF059669).withOpacity(0.6),
          shadowColor: const Color(0xFF10B981),
          icon: Icons.check_circle_rounded,
        );
      case ToastType.error:
        return _ToastColors(
          accentColor: const Color(0xFFEF4444), // Crimson Red
          borderColor: const Color(0xFFDC2626).withOpacity(0.6),
          shadowColor: const Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
        );
      case ToastType.warning:
        return _ToastColors(
          accentColor: const Color(0xFFF59E0B), // Amber Gold
          borderColor: const Color(0xD9D97706).withOpacity(0.6),
          shadowColor: const Color(0xFFF59E0B),
          icon: Icons.warning_amber_rounded,
        );
      case ToastType.info:
      default:
        return _ToastColors(
          accentColor: const Color(0xFF3B82F6), // Indigo / Sapphire
          borderColor: const Color(0xFF2563EB).withOpacity(0.6),
          shadowColor: const Color(0xFF3B82F6),
          icon: Icons.shield_rounded,
        );
    }
  }
}

class _ToastColors {
  final Color accentColor;
  final Color borderColor;
  final Color shadowColor;
  final IconData icon;

  _ToastColors({
    required this.accentColor,
    required this.borderColor,
    required this.shadowColor,
    required this.icon,
  });
}
