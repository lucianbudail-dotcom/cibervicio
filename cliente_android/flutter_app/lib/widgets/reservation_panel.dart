import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation_model.dart';
import '../services/api_config.dart';

class ReservationPanel extends StatefulWidget {
  final String? selectedDate;
  final String? formattedDate;

  const ReservationPanel({super.key, required this.selectedDate, this.formattedDate});

  @override
  State<ReservationPanel> createState() => _ReservationPanelState();
}

class _ReservationPanelState extends State<ReservationPanel> {
  bool _showTimeSelection = false;
  bool _showPcSelection = false;
  bool _showPin = false;
  bool _isCreating = false;
  String? _selectedTime;
  int? _selectedPcId;
  String? _selectedPcName;
  ReservationModel? _currentReservation;
  List<Map<String, dynamic>> _availablePcs = [];
  String? _errorMessage;

  final List<String> _hours = [
    for (int i = 8; i <= 23; i++) '${i.toString().padLeft(2, '0')}:00',
    '00:00',
  ];

  void _handleContinue() {
    if (widget.selectedDate == null) return;
    setState(() => _showTimeSelection = true);
  }

  Future<void> _loadAvailablePcs() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.equiposLibres));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['equipos'] ?? [];
        setState(() {
          _availablePcs = list.map((e) => {
            'id': e['id'] as int,
            'nombre': e['nombre']?.toString() ?? 'PC',
          }).toList();
          _errorMessage = _availablePcs.isEmpty
              ? 'No hay PCs disponibles en este momento'
              : null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error al cargar PCs disponibles');
    }
  }

  void _handleTimeSelected() {
    if (_selectedTime == null) return;
    _loadAvailablePcs();
    setState(() {
      _showPcSelection = true;
    });
  }

  Future<void> _handleConfirm() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || widget.selectedDate == null || _selectedTime == null || _selectedPcId == null) {
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    final reservation = await context.read<ReservationProvider>().createReservation(
      userId: user.id,
      email: user.email,
      equipoId: _selectedPcId!,
      date: widget.selectedDate!,
      time: _selectedTime!,
    );

    if (reservation != null) {
      setState(() {
        _currentReservation = reservation;
        _showPin = true;
        _isCreating = false;
      });
    } else {
      setState(() {
        _errorMessage = 'No se pudo crear la reserva. Puede que ya tengas una activa.';
        _isCreating = false;
      });
    }
  }

  void _handleCancel() {
    setState(() {
      _showTimeSelection = false;
      _showPcSelection = false;
      _selectedTime = null;
      _selectedPcId = null;
      _selectedPcName = null;
      _errorMessage = null;
    });
  }

  void _handleBackToTime() {
    setState(() {
      _showPcSelection = false;
      _selectedPcId = null;
      _selectedPcName = null;
      _errorMessage = null;
    });
  }

  void _handleClosePin() {
    setState(() {
      _showPin = false;
      _showTimeSelection = false;
      _showPcSelection = false;
      _selectedTime = null;
      _selectedPcId = null;
      _selectedPcName = null;
      _currentReservation = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showPin && _currentReservation != null) {
      return _buildPinView();
    }
    if (_showPcSelection && !_showPin) {
      return _buildPcSelection();
    }
    if (_showTimeSelection && !_showPin && !_showPcSelection) {
      return _buildTimeSelection();
    }
    if (widget.selectedDate == null) {
      return _buildEmpty();
    }
    return _buildDateSelected();
  }

  Widget _buildEmpty() {
    return _card(
      child: const Center(
        child: Text(
          'Selecciona un día en el calendario para reservar',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDateSelected() {
    return _card(
      child: Column(
        children: [
          const Text(
            'Fecha seleccionada:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            widget.formattedDate ?? widget.selectedDate!,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'RESERVAR PC',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    return _card(
      child: Column(
        children: [
          const Text('Fecha seleccionada:',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            widget.formattedDate ?? widget.selectedDate!,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text('Selecciona la hora:',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.8,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _hours.length,
              itemBuilder: (_, i) {
                final hour = _hours[i];
                final isSelected = _selectedTime == hour;

                // Comprobar si la hora ya pasó (solo si es hoy)
                bool isPastHour = false;
                if (widget.selectedDate != null) {
                  final now = DateTime.now();
                  final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  if (widget.selectedDate == today) {
                    final hourInt = int.tryParse(hour.split(':')[0]) ?? 0;
                    isPastHour = hourInt <= now.hour;
                  }
                }

                return GestureDetector(
                  onTap: isPastHour ? null : () => setState(() => _selectedTime = hour),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isPastHour
                          ? const Color(0xFF6750A4).withOpacity(0.1)
                          : isSelected
                              ? const Color(0xFF6750A4).withOpacity(0.9)
                              : const Color(0xFF6750A4).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        hour,
                        style: TextStyle(
                            color: isPastHour ? Colors.white24 : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedTime != null ? _handleTimeSelected : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Siguiente',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPcSelection() {
    return _card(
      child: Column(
        children: [
          Text(
            widget.formattedDate ?? widget.selectedDate!,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Text('Hora: $_selectedTime',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          const Text('Elige tu PC:',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center),
            )
          else if (_availablePcs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF6750A4)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6750A4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: _availablePcs.map((pc) {
                  final isSelected = _selectedPcId == pc['id'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedPcId = pc['id'] as int;
                      _selectedPcName = pc['nombre'] as String;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6750A4).withOpacity(0.9)
                            : const Color(0xFF6750A4).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.computer,
                            color: isSelected ? Colors.white : Colors.white60,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            pc['nombre'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleBackToTime,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Atrás'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedPcId != null && !_isCreating) ? _handleConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmar',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinView() {
    final r = _currentReservation!;
    return _card(
      child: Column(
        children: [
          const Text(
            '¡Reserva Confirmada!',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(_selectedPcName ?? 'PC Nº ${r.pcNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(widget.formattedDate ?? widget.selectedDate!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Text('Hora: ${r.time}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text('Tu PIN de acceso:',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  r.pin,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Introduce este PIN en el PC del Ciber para desbloquearlo',
            style: TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '✓ Podrás ver tu PIN en "Mis Reservas" cuando lo necesites',
            style: TextStyle(color: Color(0xFF4ADE80), fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleClosePin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Entendido',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
