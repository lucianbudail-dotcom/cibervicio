import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _showCodeInput = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_phoneCtrl.text.isNotEmpty) {
      setState(() => _showCodeInput = true);
    }
  }

  void _handleConfirmCode() {
    if (_codeCtrl.text == '123456') {
      context.go('/password-reset', extra: _phoneCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Stack(
        children: [
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF403757), Colors.transparent],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showCodeInput ? _buildCodeView() : _buildPhoneView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneView() {
    return Column(
      key: const ValueKey('phone'),
      children: [
        const Text('Recuperar Contraseña',
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Te enviaremos un código por SMS para verificar tu identidad.',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Número de teléfono:',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '123456789',
                  hintStyle: const TextStyle(color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Enviar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeView() {
    return Column(
      key: const ValueKey('code'),
      children: [
        const Text('Verificar Código',
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text('Ingresa aquí el código que te hemos enviado.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Código:',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeCtrl,
                maxLength: 6,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    color: Colors.black87, fontSize: 24, letterSpacing: 6),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '123456',
                  hintStyle: const TextStyle(color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFD9D9D9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleConfirmCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Confirmar',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Código de prueba: 123456',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
