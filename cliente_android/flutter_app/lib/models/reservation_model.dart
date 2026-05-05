class ReservationModel {
  final String id;
  final String userId;
  final String date;
  final String time;
  final int pcNumber;
  final String pcName;
  final String pin;
  final bool claimed;      // usada = 1 (PIN fue usado en el cliente PC)
  final bool isCompleted;  // activa = 0 (ya no es una reserva activa)
  final bool wasCancelled; // activa = 0 AND usada = 0 (fue cancelada, no usada)
  final String createdAt;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.time,
    required this.pcNumber,
    this.pcName = '',
    required this.pin,
    this.claimed = false,
    this.isCompleted = false,
    this.wasCancelled = false,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final int activa = (json['activa'] is int) ? json['activa'] : (int.tryParse(json['activa']?.toString() ?? '1') ?? 1);
    final int usada = (json['usada'] is int) ? json['usada'] : (int.tryParse(json['usada']?.toString() ?? '0') ?? 0);

    return ReservationModel(
      id: json['id']?.toString() ?? '',
      userId: json['usuario_id']?.toString() ?? json['userId']?.toString() ?? '',
      date: json['fecha'] ?? json['date'] ?? '',
      time: json['hora'] ?? json['time'] ?? '',
      pcNumber: (json['equipo_id'] as int?) ?? (json['pcNumber'] as int?) ?? 0,
      pcName: json['equipo_nombre']?.toString() ?? '',
      pin: json['pin']?.toString() ?? '',
      claimed: usada == 1,
      isCompleted: activa == 0,
      wasCancelled: activa == 0 && usada == 0,
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
    );
  }

  /// Devuelve true si ha pasado más de 1 hora desde la hora de la reserva
  bool get isPinExpired {
    try {
      // Parsear fecha (YYYY-MM-DD) y hora (HH:MM o HH:MM:SS)
      final dateParts = date.split('-');
      final timeParts = time.split(':');
      if (dateParts.length < 3 || timeParts.length < 2) return false;

      final reservationDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final now = DateTime.now();
      final difference = now.difference(reservationDateTime);
      return difference.inHours >= 1;
    } catch (e) {
      return false;
    }
  }

  /// Reserva activa = activa == 1 (no completada ni cancelada)
  bool get isActive => !isCompleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': userId,
      'fecha': date,
      'hora': time,
      'equipo_id': pcNumber,
      'equipo_nombre': pcName,
      'pin': pin,
      'usada': claimed ? 1 : 0,
      'activa': isCompleted ? 0 : 1,
      'created_at': createdAt,
    };
  }

  ReservationModel copyWith({bool? claimed, bool? isCompleted}) {
    return ReservationModel(
      id: id,
      userId: userId,
      date: date,
      time: time,
      pcNumber: pcNumber,
      pcName: pcName,
      pin: pin,
      claimed: claimed ?? this.claimed,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}
