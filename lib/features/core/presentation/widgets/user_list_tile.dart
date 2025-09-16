import 'package:flutter/material.dart';

class UserListTile extends StatelessWidget {
  final String title;
  const UserListTile({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title));
  }
}
