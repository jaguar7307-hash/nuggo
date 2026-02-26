import 'dart:io';
void main() {
  final b = File(r'C:\Users\jagua\Desktop\nuggo\encoding_result.txt').readAsBytesSync();
  print('Bytes: ${b.map((x) => x.toRadixString(16)).join(' ')}');
  // Expected: eb b3 b4 eb 82 b4 ea b8 b0 for 보내기 in UTF-8
}
