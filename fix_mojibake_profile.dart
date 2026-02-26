import 'dart:convert';
import 'dart:io';

bool _looksMojibake(String line) {
  // Common UTF-8->Latin1 mojibake markers in Korean text.
  return line.contains('Ã') ||
      line.contains('Â') ||
      line.contains('ë') ||
      line.contains('ì') ||
      line.contains('í');
}

String _repairLine(String line) {
  if (!_looksMojibake(line)) return line;
  try {
    final bytes = latin1.encode(line);
    final repaired = utf8.decode(bytes);
    return repaired;
  } catch (_) {
    return line;
  }
}

void main() {
  final path =
      r'c:\Users\jagua\Desktop\nuggo\nuggo_flutter\lib\screens\profile_screen.dart';
  final file = File(path);
  final original = file.readAsStringSync();
  final lines = original.split('\n');
  final fixed = lines.map(_repairLine).join('\n');
  file.writeAsStringSync(fixed);
  print('profile_screen mojibake repair done');
}
