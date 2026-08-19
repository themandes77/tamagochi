import 'package:flutter/material.dart';

/// Burbuja visual de NTI / mensajes contextuales de Home.
///
/// Las necesidades no se comunican con este componente: NTI las expresa con
/// cara, postura, movimiento y efectos. El uso compacto queda disponible para
/// el Zzz aprobado del estado de descanso.
class PetMessageBubble extends StatelessWidget {
  const PetMessageBubble({
    required this.message,
    this.compact = false,
    super.key,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 18.0 : 20.0;
    final verticalPadding = compact ? 9.0 : 11.0;
    final radius = compact ? 19.0 : 22.0;

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey<String>('${compact ? 'compact' : 'normal'}:$message'),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final pop = Curves.easeOutBack.transform(value);
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.90 + pop * 0.10,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            Container(
              constraints: BoxConstraints(
                minWidth: compact ? 92 : 0,
                maxWidth: compact ? 150 : 310,
              ),
              margin: const EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: const Color(0xFF6D3AA5), width: 2.4),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF4A2A67).withValues(alpha: 0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                message,
                maxLines: compact ? 1 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF3D3048),
                  fontFamily: 'Fredoka',
                  fontSize: compact ? 16 : 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                ),
              ),
            ),
            const Positioned(
              right: 10,
              top: -4,
              child: Text(
                '✦',
                style: TextStyle(
                  color: Color(0xFFE2AA37),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  shadows: <Shadow>[
                    Shadow(
                      color: Color(0x335A356F),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 0,
              child: CustomPaint(
                size: Size(22, 13),
                painter: _PetBubbleTailPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetBubbleTailPainter extends CustomPainter {
  const _PetBubbleTailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(size.width / 2, size.height - 1)
      ..lineTo(size.width - 1, 1)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF1D6));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF6D3AA5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PetBubbleTailPainter oldDelegate) => false;
}
