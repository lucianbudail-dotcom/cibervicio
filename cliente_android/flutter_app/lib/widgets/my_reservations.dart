import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reservation_provider.dart';
import '../models/reservation_model.dart';

class MyReservations extends StatefulWidget {
  const MyReservations({super.key});

  @override
  State<MyReservations> createState() => _MyReservationsState();
}

class _MyReservationsState extends State<MyReservations> {
  String? _showCancelConfirm;
  String? _claimingId;
  String _claimPin = '';
  String _claimError = '';
  String? _showPinId;
  bool _showHistory = false;
  bool _initialLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoaded) {
      _initialLoaded = true;
      _loadReservations();
    }
  }

  Future<void> _loadReservations() async {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      await context.read<ReservationProvider>().fetchUserReservations(user.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final provider = context.watch<ReservationProvider>();
    final userReservations = provider.getUserReservations(user.id);
    final userHistory = provider.getUserHistory(user.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _showHistory ? 'Historial de Reservas' : 'Mis Reservas',
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _loadReservations,
                  icon: const Icon(Icons.refresh, color: Color(0xFF6750A4), size: 20),
                  tooltip: 'Actualizar',
                ),
                TextButton(
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  child: Text(
                    _showHistory ? 'Ver Activas' : 'Ver Historial',
                    style: const TextStyle(color: Color(0xFF6750A4)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (provider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF6750A4)),
            ),
          )
        else if (!_showHistory) ...[
          if (userReservations.isEmpty)
            _buildEmptyState('No tienes reservas activas')
          else
            ...userReservations.map((r) => _buildCard(context, r)),
        ] else ...[
          if (userHistory.isEmpty)
            _buildEmptyState('Tu historial está vacío')
          else
            ...userHistory.reversed.map((r) => _buildHistoryCard(r)),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white60, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCard(BuildContext context, ReservationModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.claimed 
            ? const Color(0xFF1B5E20).withOpacity(0.1)
            : const Color(0xFF2E2E2E).withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        border: r.claimed 
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)
        ],
      ),
      child: _showCancelConfirm == r.id
          ? _buildCancelConfirm(context, r.id)
          : _claimingId == r.id
              ? _buildClaimView(context, r.id)
              : _buildNormalView(context, r),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final day = parts[2];
      final month = parts[1];
      
      final months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
      final monthIndex = int.parse(month) - 1;
      if (monthIndex < 0 || monthIndex >= 12) return dateStr;
      
      return "$day de ${months[monthIndex]} ${parts[0]}";
    } catch (e) {
      return dateStr;
    }
  }

  String _getPcDisplayName(ReservationModel r) {
    if (r.pcName.isNotEmpty) return r.pcName;
    return 'PC Nº ${r.pcNumber}';
  }

  Widget _buildHistoryCard(ReservationModel r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E2E).withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getPcDisplayName(r),
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${_formatDate(r.date)} - ${r.time}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          Text(
            r.wasCancelled ? 'Cancelada' : 'Completada',
            style: TextStyle(
              color: r.wasCancelled ? Colors.orange.shade300 : Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelConfirm(BuildContext context, String id) {
    return Column(
      children: [
        const Text('¿Seguro que quieres cancelar esta reserva?',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showCancelConfirm = null),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('No'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final user = context.read<AuthProvider>().user;
                  await context.read<ReservationProvider>().cancelReservation(
                    id,
                    email: user?.email,
                  );
                  setState(() => _showCancelConfirm = null);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimView(BuildContext context, String id) {
    return Column(
      children: [
        const Text('Confirmar reserva', style: TextStyle(color: Colors.white, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Ingresa tu PIN de 4 dígitos', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFF6750A4).withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            hintText: '****',
            hintStyle: const TextStyle(color: Colors.white30),
          ),
          onChanged: (v) => setState(() {
            _claimPin = v.replaceAll(RegExp(r'\D'), '');
            _claimError = '';
          }),
        ),
        if (_claimError.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_claimError, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _claimingId = null;
                  _claimPin = '';
                  _claimError = '';
                }),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _claimPin.length == 4
                    ? () async {
                        final error = await context.read<ReservationProvider>().claimReservation(id, _claimPin);
                        if (error == null) {
                          setState(() {
                            _claimingId = null;
                            _claimPin = '';
                            _claimError = '';
                          });
                          // Recargar reservas del servidor
                          _loadReservations();
                        } else {
                          setState(() => _claimError = error);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNormalView(BuildContext context, ReservationModel r) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getPcDisplayName(r),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${_formatDate(r.date)} - ${r.time}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.claimed ? Colors.green.withOpacity(0.6) : const Color(0xFF6750A4).withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(r.claimed ? 'En curso' : 'Activa',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!r.claimed) ...[
          if (r.isPinExpired)
            // PIN expirado: mostrar aviso
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.orange.shade300, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'PIN expirado. Ha pasado más de 1h desde la hora de la reserva.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _showPinId == r.id ? _buildPinDisplay(r) : _buildPinHidden(r),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showCancelConfirm = r.id),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
              ),
              if (!r.isPinExpired) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() { _claimingId = r.id; _claimPin = ''; _claimError = ''; }),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4).withOpacity(0.79),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Sesión activa. ¡Disfruta tu tiempo!',
                      style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
                TextButton(
                  onPressed: () => context.read<ReservationProvider>().completeReservation(r.id, r.pcNumber),
                  child: const Text('Finalizar', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPinDisplay(ReservationModel r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF6750A4).withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tu PIN:', style: TextStyle(color: Colors.white70, fontSize: 11)),
              GestureDetector(onTap: () => setState(() => _showPinId = null), child: const Text('✕', style: TextStyle(color: Colors.white60))),
            ],
          ),
          Text(r.pin, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8)),
        ],
      ),
    );
  }

  Widget _buildPinHidden(ReservationModel r) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('PIN de acceso listo', style: TextStyle(color: Colors.white60, fontSize: 12)),
          GestureDetector(
            onTap: () => setState(() => _showPinId = r.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF6750A4).withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
              child: const Text('Ver PIN', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
