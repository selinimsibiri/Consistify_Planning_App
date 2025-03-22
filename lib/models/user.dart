class User {
  final int? id;
  final String username;
  final String email;
  final String passwordHash;
  final int coins;
  final DateTime? createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.coins = 0,
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        email: json['email'],
        passwordHash: json['password_hash'],
        coins: json['coins'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'email': email,
        'password_hash': passwordHash,
        'coins': coins,
        'created_at': createdAt?.toIso8601String(),
      };
}
