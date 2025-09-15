import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/group.dart';

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final id = reader.readString();
    final email = reader.readString();
    final password = reader.readString();
    final name = reader.readString();
    return User(id: id, email: email, password: password, name: name);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.email);
    writer.writeString(obj.password);
    writer.writeString(obj.name);
  }
}

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 1;

  @override
  Course read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final description = reader.readString();
    final teacherId = reader.readString();
    final registrationCode = reader.readString();
    final studentsLength = reader.readInt();
    final students = <String>[];
    for (var i = 0; i < studentsLength; i++) {
      students.add(reader.readString());
    }
    final invitesLength = reader.readInt();
    final invites = <String>[];
    for (var i = 0; i < invitesLength; i++) {
      invites.add(reader.readString());
    }
    return Course(id: id, name: name, description: description, teacherId: teacherId, registrationCode: registrationCode, studentIds: students);
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.teacherId);
    writer.writeString(obj.registrationCode);
    writer.writeInt(obj.studentIds.length);
    for (final s in obj.studentIds) {
      writer.writeString(s);
    }
    writer.writeInt(obj.invitations.length);
    for (final e in obj.invitations) {
      writer.writeString(e);
    }
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 2;

  @override
  Category read(BinaryReader reader) {
    final id = reader.readString();
    final courseId = reader.readString();
    final name = reader.readString();
    final randomAssign = reader.readBool();
    final studentsPerGroup = reader.readInt();
    return Category(id: id, courseId: courseId, name: name, randomAssign: randomAssign, studentsPerGroup: studentsPerGroup);
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.courseId);
    writer.writeString(obj.name);
    writer.writeBool(obj.randomAssign);
    writer.writeInt(obj.studentsPerGroup);
  }
}

class GroupAdapter extends TypeAdapter<Group> {
  @override
  final int typeId = 3;

  @override
  Group read(BinaryReader reader) {
    final id = reader.readString();
    final categoryId = reader.readString();
    final name = reader.readString();
    final membersLength = reader.readInt();
    final members = <String>[];
    for (var i = 0; i < membersLength; i++) {
      members.add(reader.readString());
    }
    return Group(id: id, categoryId: categoryId, name: name, memberIds: members);
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.categoryId);
    writer.writeString(obj.name);
    writer.writeInt(obj.memberIds.length);
    for (final m in obj.memberIds) {
      writer.writeString(m);
    }
  }
}
