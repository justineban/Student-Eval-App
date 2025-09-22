typedef IdGenerator = String Function();
typedef CodeGenerator = String Function();

String defaultIdGenerator() => DateTime.now().microsecondsSinceEpoch.toString();

String defaultCourseCodeGenerator() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final now = DateTime.now().microsecondsSinceEpoch;
  final buffer = StringBuffer();
  for (int i = 0; i < 6; i++) {
    buffer.write(chars[(now + i * 37) % chars.length]);
  }
  return buffer.toString();
}
