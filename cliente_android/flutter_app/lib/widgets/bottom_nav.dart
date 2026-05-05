import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_drawing/path_drawing.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  bool _isActive(BuildContext context, String path) {
    return GoRouterState.of(context).matchedLocation == path;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 412,
      height: 124,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Capa 1: Barra exterior
          Positioned(
            left: -32,
            top: 0,
            child: Container(
              width: 474,
              height: 124,
              decoration: BoxDecoration(
                color: const Color(0xFF48464C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(31.455),
              ),
            ),
          ),
          // Capa 2: Píldora media
          Positioned(
            left: 15.18,
            top: 16.61,
            child: Container(
              width: 378.542,
              height: 79.714,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9).withOpacity(0.2),
                borderRadius: BorderRadius.circular(1000), // Simula el redondeo masivo
              ),
            ),
          ),
          // Capa 3: Píldora interior con sombra
          Positioned(
            left: 33.83,
            top: 26.57,
            child: Container(
              width: 341.236,
              height: 58.679,
              decoration: BoxDecoration(
                color: const Color(0xFF938F99).withOpacity(0.96),
                borderRadius: BorderRadius.circular(1000),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    offset: const Offset(0, 4.102),
                    blurRadius: 4.102,
                  ),
                ],
              ),
            ),
          ),

          // Botón Calendario
          Positioned(
            left: 76,
            top: 37.71,
            child: _NavButton(
              path: '/calendar',
              width: 40.19,
              height: 40.19,
              isActive: _isActive(context, '/calendar'),
              iconPainter: CalendarIconPainter(),
            ),
          ),

          // Botón Puntos (Estrella)
          Positioned(
            left: 187.17,
            top: 34.66,
            child: _NavButton(
              path: '/points',
              width: 41.756,
              height: 41.756,
              isActive: _isActive(context, '/points'),
              iconPainter: StarIconPainter(),
            ),
          ),

          // Botón Perfil
          Positioned(
            left: 299.72,
            top: 37.7,
            child: _NavButton(
              path: '/profile',
              width: 34.649,
              height: 40.712,
              isActive: _isActive(context, '/profile'),
              iconPainter: ProfileIconPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String path;
  final double width;
  final double height;
  final bool isActive;
  final CustomPainter iconPainter;

  const _NavButton({
    required this.path,
    required this.width,
    required this.height,
    required this.isActive,
    required this.iconPainter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: iconPainter,
          ),
        ),
      ),
    );
  }
}

class CalendarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintPurple = Paint()
      ..color = const Color(0xFF6750A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.73
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintDark = Paint()
      ..color = const Color(0xFF292929)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.73
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Escalar para que quepa en el viewBox original de ~32.76
    canvas.scale(size.width / 32.76);

    // Línea horizontal
    canvas.drawLine(const Offset(5.46, 10.92), const Offset(27.3, 10.92), paintPurple);

    // Cuerpo calendario
    final pathBody = parseSvgPathData("M5.45997 5.45997H27.2999V24.5699C27.2999 26.0776 26.0776 27.2999 24.5699 27.2999H8.18996C6.68223 27.2999 5.45997 26.0776 5.45997 24.5699V5.45997Z");
    canvas.drawPath(pathBody, paintDark);

    // Líneas verticales arriba
    canvas.drawLine(const Offset(21.84, 4.09), const Offset(21.84, 6.82), paintDark);
    canvas.drawLine(const Offset(10.92, 4.09), const Offset(10.92, 6.82), paintDark);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class StarIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintPurple = Paint()
      ..color = const Color(0xFF6750A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.76
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintDark = Paint()
      ..color = const Color(0xFF292929)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.76
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 33.12);

    final path1 = parseSvgPathData("M14.4192 7.40291L12.2777 12.0457L2.12307 13.2497L9.63066 20.1925L7.63777 30.2222L16.5607 25.2275L25.4837 30.2222L23.4908 20.1925L27.2446 16.7211");
    canvas.drawPath(path1, paintDark);

    final path2 = parseSvgPathData("M14.4192 7.40291L16.5607 2.76012L20.8438 12.0457L30.9984 13.2497L27.2446 16.7211");
    canvas.drawPath(path2, paintPurple);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ProfileIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintPurple = Paint()
      ..color = const Color(0xFF6750A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.94;

    final paintDark = Paint()
      ..color = const Color(0xFF292929)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.94
      ..strokeJoin = StrokeJoin.round;

    canvas.scale(size.width / 35.23);

    final pathRect = parseSvgPathData("M5.87189 26.4243C5.87189 23.1812 8.5009 20.5522 11.744 20.5522H23.4881C26.7312 20.5522 29.3602 23.1812 29.3602 26.4243C29.3602 28.0458 28.0457 29.3603 26.4241 29.3603H8.80792C7.1864 29.3603 5.87189 28.0458 5.87189 26.4243Z");
    canvas.drawPath(pathRect, paintDark);

    canvas.drawCircle(const Offset(17.616, 10.2761), 4.404, paintPurple);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
