import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

// #region agent log
const String _kSessionId = '9988cb';
const String _kEndpoint =
    'http://127.0.0.1:7413/ingest/6dbd83f8-f651-4713-af0a-e01d234374db';

void debugScrollLog({
  required String location,
  required String message,
  Map<String, dynamic>? data,
  String? hypothesisId,
  String? runId,
}) {
  if (!kDebugMode) return;
  final payload = <String, dynamic>{
    'sessionId': _kSessionId,
    'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    if (data != null) 'data': data,
    if (hypothesisId != null) 'hypothesisId': hypothesisId,
    if (runId != null) 'runId': runId,
  };
  unawaited(
    () async {
      try {
        await http.post(
          Uri.parse(_kEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': _kSessionId,
          },
          body: jsonEncode(payload),
        );
      } catch (_) {}
    }(),
  );
}
// #endregion
