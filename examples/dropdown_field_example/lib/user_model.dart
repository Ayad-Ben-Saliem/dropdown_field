const users = [
  User(firstName: 'Mohammed', email: 'mohammed@gmail.com'),
  User(firstName: 'Omar', email: 'omar@gmail.com'),
  User(firstName: 'Ali', email: 'ali@gmail.com'),
  User(firstName: 'Ayad', email: 'ayad@gmail.com'),
];


class User {
  final String firstName;
  final String? lastName;
  final String email;
  final String? password;

  const User({
    required this.firstName,
    this.lastName,
    required this.email,
    this.password,
  });

  String get fullName => '$firstName ${lastName ?? '\b'}';

  @override
  String toString() => '$firstName ($email)';

  @override
  bool operator ==(Object other) {
    if (other is User) {
      return firstName == other.firstName && lastName == other.lastName && email == other.email && password == other.password;
    }
    return super == other;
  }

  @override
  int get hashCode => '$firstName ${lastName ?? ''} $email ${password ?? ''}'.hashCode;

}
