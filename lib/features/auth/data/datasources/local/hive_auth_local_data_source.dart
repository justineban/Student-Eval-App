import 'package:hive/hive.dart';

class HiveAuthLocalDataSource {
  final Box usersBox;
  final Box sessionBox;
  HiveAuthLocalDataSource({required this.usersBox, required this.sessionBox});

  bool emailExists(String email) => usersBox.values.any((u) => u.email == email);
  dynamic getUser(String id) => usersBox.get(id);
  Iterable<dynamic> getAllUsers() => usersBox.values;
  Future<void> putUser(String id, dynamic value) => usersBox.put(id, value);

  void persistCurrentUserId(String id) => sessionBox.put('currentUserId', id);
  String? loadCurrentUserId() => sessionBox.get('currentUserId') as String?;
  void clearSession() => sessionBox.delete('currentUserId');
}
