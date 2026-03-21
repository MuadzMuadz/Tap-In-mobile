class ProfileModel {
  final String id;
  final String? storeName;
  final String? qrisUrl;
  final String? qrisString;

  const ProfileModel({
    required this.id,
    this.storeName,
    this.qrisUrl,
    this.qrisString,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      storeName: json['store_name'] as String?,
      qrisUrl: json['qris_url'] as String?,
      qrisString: json['qris_string'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'store_name': storeName,
        'qris_url': qrisUrl,
        'qris_string': qrisString,
      };

  ProfileModel copyWith({
    String? storeName,
    String? qrisUrl,
    String? qrisString,
  }) {
    return ProfileModel(
      id: id,
      storeName: storeName ?? this.storeName,
      qrisUrl: qrisUrl ?? this.qrisUrl,
      qrisString: qrisString ?? this.qrisString,
    );
  }
}
