class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String birthdate;
  final int points;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthdate,
    this.points = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['telefono']?.toString() ?? json['phone']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      birthdate: json['fecha_nacimiento']?.toString() ?? json['birthdate']?.toString() ?? '',
      points: int.tryParse(json['puntos']?.toString() ?? '0') ?? 
              int.tryParse(json['points']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'telefono': phone,
      'password': password,
      'fecha_nacimiento': birthdate,
      'puntos': points,
    };
  }

  UserModel copyWith({int? points}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      phone: phone,
      password: password,
      birthdate: birthdate,
      points: points ?? this.points,
    );
  }
}
