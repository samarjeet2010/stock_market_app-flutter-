class UserModel {
  final String userId;
  final String email;
  final String name;
  final double virtualBalance;
  final String riskProfile;
  final String? avatarData; // base64 image data (data URI without prefix)
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.virtualBalance,
    required this.riskProfile,
    this.avatarData,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'name': name,
    'virtualBalance': virtualBalance,
    'riskProfile': riskProfile,
    'avatarData': avatarData,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: json['userId'] as String,
    email: json['email'] as String,
    name: json['name'] as String,
    virtualBalance: (json['virtualBalance'] as num).toDouble(),
    riskProfile: json['riskProfile'] as String,
    avatarData: json['avatarData'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    double? virtualBalance,
    String? riskProfile,
    String? avatarData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserModel(
    userId: userId ?? this.userId,
    email: email ?? this.email,
    name: name ?? this.name,
    virtualBalance: virtualBalance ?? this.virtualBalance,
    riskProfile: riskProfile ?? this.riskProfile,
    avatarData: avatarData ?? this.avatarData,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
