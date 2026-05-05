import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final String? successMessage;
  const LoginScreen({super.key, this.successMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos');
      return;
    }
    setState(() => _loading = true);
    final success = await context.read<AuthProvider>().login(
      _usernameCtrl.text,
      _passwordCtrl.text,
    );
    setState(() => _loading = false);
    if (success) {
      context.go('/calendar');
    } else {
      setState(() => _error = 'Usuario o contraseña incorrectos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: SingleChildScrollView(
        child: SizedBox(
          width: 412,
          height: 915,
          child: Stack(
            children: [
              // Bottom gradient blur
              Positioned(
                left: -13.16,
                top: 547.44,
                child: Container(
                  width: 438.433,
                  height: 303.457,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF29B1D6),
                        Color(0xFF46D3EF),
                        Color(0xFF68A1C7),
                        Color(0xFF33375B),
                        Color(0xFF030C15),
                      ],
                      stops: [0.35966, 0.37486, 0.39006, 0.41012, 0.42715],
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.528, sigmaY: 6.528),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              // Blurred image
              Positioned(
                left: -419.08,
                top: 0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 7.021, sigmaY: 7.021),
                  child: Image.asset(
                    'assets/images/login_bg.png',
                    width: 1014.907,
                    height: 568.222,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Top purple decorative
              Positioned(
                left: -65.82,
                top: 0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 35.8, sigmaY: 35.8),
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(
                      width: 540.858,
                      height: 526.596,
                      decoration: const BoxDecoration(
                        color: Color(0xFF403757),
                        shape: BoxShape.rectangle,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom decorative shapes
              Positioned(
                left: -79.55,
                top: 582,
                child: Opacity(
                  opacity: 0.5,
                  child: CustomPaint(
                    size: const Size(490.954, 245.198),
                    painter: _ShapePainter(color: const Color(0xFF6750A4)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 563.9,
                child: Opacity(
                  opacity: 0.6,
                  child: CustomPaint(
                    size: const Size(481.616, 263.298),
                    painter: _ShapePainter(color: const Color(0xFF574E70)),
                  ),
                ),
              ),

              // Title "Ciber Vicio"
              Positioned(
                left: 194.67 - 200,
                top: 100, // Ajustado para que se vea más centrado como en React
                child: SizedBox(
                  width: 400.308,
                  child: Column(
                    children: [
                      Text(
                        'Ciber',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 145.018,
                          fontFamily: 'Fustat',
                          height: 0.6,
                          fontWeight: FontWeight.w100,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(7.625, 10.167),
                              blurRadius: 3.812,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                      Text(
                        'Vicio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 145.018,
                          fontFamily: 'Fustat',
                          height: 0.6,
                          fontWeight: FontWeight.w100,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(7.625, 10.167),
                              blurRadius: 3.812,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form container background
              Positioned(
                left: 46.08,
                top: 432.25,
                child: Container(
                  width: 319.249,
                  height: 249.036,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E2E2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // Labels and Inputs
              Positioned(
                left: 66.92,
                top: 450,
                child: const Text(
                  'Usuario:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.966,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 66.92,
                top: 477.23,
                child: _buildInput(_usernameCtrl, 'Usuario', false),
              ),

              Positioned(
                left: 66.92,
                top: 550,
                child: const Text(
                  'Contraseña:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.966,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 66.92,
                top: 579.26,
                child: _buildInput(_passwordCtrl, 'Contraseña', true),
              ),

              // Forgot password
              Positioned(
                left: 155.78 - 70,
                top: 651.11 - 10,
                child: GestureDetector(
                  onTap: () => context.go('/password-recovery'),
                  child: SizedBox(
                    width: 179.92,
                    child: const Text(
                      '¿Has olvidado tu contraseña?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.434,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Login Button
              Positioned(
                left: 30,
                top: 699,
                child: GestureDetector(
                  onTap: _handleLogin,
                  child: SizedBox(
                    width: 349,
                    height: 55.776,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withOpacity(0.79),
                            borderRadius: BorderRadius.circular(58.896),
                            border: Border(
                              right: BorderSide(color: Colors.black.withOpacity(0.47), width: 3.218),
                              bottom: BorderSide(color: Colors.black.withOpacity(0.47), width: 3.218),
                            ),
                          ),
                        ),
                        Center(
                          child: _loading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25.89,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 4.29),
                                    blurRadius: 4.29,
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Register Link
              Positioned(
                left: 412 / 2 - 100,
                top: 771.97 - 10,
                child: SizedBox(
                  width: 200,
                  child: GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      '¿No tienes cuenta? Regístrate.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.434,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Status Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _StatusBar(),
              ),

              if (_error.isNotEmpty)
                Positioned(
                  top: 390,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, bool obscure) {
    return Container(
      width: 279.754,
      height: 53.757,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(3.291),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4.388),
            blurRadius: 4.388,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('9:41', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              const Icon(Icons.wifi, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Container(
                width: 22,
                height: 11,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 17,
                    height: 7,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final Color color;
  _ShapePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
