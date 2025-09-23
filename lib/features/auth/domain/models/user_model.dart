//   of core/entities/user.dart for auth module (detached)
class UserModel  {
  final String id;
  String email;
  String password;
  String name;

  UserModel ({required this.id, required this.email, required this.password, required this.name});
}
