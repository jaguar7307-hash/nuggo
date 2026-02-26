import 'dart:io';
void main() {
  // Check fix_profile.dart for Korean bytes
  // 보내기 = EB B3 B4 EB 82 B4 EA B8 B0
  final f2 = File(r'C:\Users\jagua\Desktop\nuggo\nuggo_flutter\lib\screens\profile_screen.dart');
  final bytes2 = f2.readAsBytesSync();
  // Show bytes around line 297 (label: _tr...) 
  // Find "label: _tr(language, '"
  final marker = "label: _tr(language, '".codeUnits;
  List<int> positions = [];
  for (int i = 0; i < bytes2.length - marker.length; i++) {
    bool match = true;
    for (int j = 0; j < marker.length; j++) {
      if (bytes2[i+j] != marker[j]) { match = false; break; }
    }
    if (match) positions.add(i);
  }
  print('Found "label: _tr(language, \'" at ${positions.length} positions');
  for (int pos in positions.take(5)) {
    print('At $pos: ${bytes2.sublist(pos, pos + 50).map((b) => b.toRadixString(16).padLeft(2,'0')).join(' ')}');
  }
}
