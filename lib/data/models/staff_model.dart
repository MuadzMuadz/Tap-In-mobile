class StaffModel {
  final String id;
  final String userId;
  final String name;
  final String pin;
  final bool isOwner;
  final DateTime createdAt;

  const StaffModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.pin,
    required this.isOwner,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      pin: json['pin'] as String,
      isOwner: json['is_owner'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'pin': pin,
        'is_owner': isOwner,
      };
}
