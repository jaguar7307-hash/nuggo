import 'dart:io';
void main() {
  // Test: 보내기 = U+BCF4 U+B0B4 U+AE30
  const s = '보내기';
  print('Length: ${s.length}');
  for (final ch in s.runes) {
    print('  U+${ch.toRadixString(16).toUpperCase().padLeft(4,'0')}');
  }
  // Write the test file
  File(r'C:\Users\jagua\Desktop\nuggo\encoding_result.txt').writeAsStringSync(s);
}
