class User {
  final String firstName;
  final String? lastName;
  final String email;
  final String? password;

  User({
    required this.firstName,
    this.lastName,
    required this.email,
    this.password,
  });

  @override
  String toString() => '$firstName ($email)';
}
