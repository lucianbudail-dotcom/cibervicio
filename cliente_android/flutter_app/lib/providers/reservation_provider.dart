import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/reservation_model.dart';
import '../services/api_config.dart';

class ReservationProvider extends ChangeNotifier {
  List<ReservationModel> _reservations = [];
  bool _isLoading = false;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoading => _isLoading;

  /// Cargar reservas del usuario desde el servidor
  Future<void> fetchUserReservations(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(Uri.parse('${ApiConfig.misReservas}/$email'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['reservas'] ?? [];
        _reservations = list.map((e) => ReservationModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetch reservas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crear una reserva y recargar del servidor para obtener el ID real
  Future<ReservationModel?> createReservation({
    required String userId,
    required String email,
    required int equipoId,
    String? date,
    String? time,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reservas),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': int.parse(userId),
          'equipo_id': equipoId,
          'date': date,
          'time': time,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Recargar reservas del servidor para obtener el ID real
        await fetchUserReservations(email);

        // Buscar la reserva recién creada (la más reciente con ese PIN)
        final pin = data['pin'].toString();
        final found = _reservations.where((r) => r.pin == pin && r.isActive).toList();
        if (found.isNotEmpty) {
          return found.first;
        }

        // Fallback: devolver un modelo temporal con los datos
        return ReservationModel(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          date: date ?? DateTime.now().toIso8601String().split('T')[0],
          time: time ?? DateTime.now().toIso8601String().split('T')[1].substring(0, 5),
          pcNumber: equipoId,
          pin: pin,
          createdAt: DateTime.now().toIso8601String(),
        );
      } else {
        final data = jsonDecode(response.body);
        debugPrint('Error crear reserva: ${data['message']}');
      }
      return null;
    } catch (e) {
      debugPrint('Error create reserva: $e');
      return null;
    }
  }

  /// Cancelar una reserva en el servidor y recargar
  Future<bool> cancelReservation(String id, {String? email}) async {
    try {
      // Solo llamar al backend si tiene un ID real
      if (!id.startsWith('temp-')) {
        final response = await http.delete(Uri.parse('${ApiConfig.reservas}/$id'));
        if (response.statusCode != 200) {
          debugPrint('Error cancel reserva en servidor');
          return false;
        }
      }

      // Recargar del servidor si tenemos email
      if (email != null) {
        await fetchUserReservations(email);
      } else {
        // Eliminar localmente como fallback
        _reservations.removeWhere((r) => r.id == id);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error cancel reserva: $e');
      // Eliminar localmente como fallback
      _reservations.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    }
  }

  Future<String?> claimReservation(String id, String pin) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reservas/validar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );
      if (response.statusCode == 200) {
        final index = _reservations.indexWhere((r) => r.id == id);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(claimed: true, isCompleted: true);
          notifyListeners();
        }
        return null;
      } else {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Error al validar';
      }
    } catch (e) {
      return 'Error de conexión';
    }
  }

  Future<void> completeReservation(String id, int equipoId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reservas/liberar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'equipo_id': equipoId}),
      );

      if (response.statusCode == 200) {
        final index = _reservations.indexWhere((r) => r.id == id);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(isCompleted: true);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error complete reserva: $e');
    }
  }

  /// Reservas activas del usuario (activa = 1, no completadas)
  List<ReservationModel> getUserReservations(String userId) {
    return _reservations.where((r) => r.isActive).toList();
  }

  /// Historial: reservas completadas o canceladas (activa = 0)
  List<ReservationModel> getUserHistory(String userId) {
    return _reservations.where((r) => r.isCompleted).toList();
  }
}
