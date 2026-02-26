import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;

// #region agent log
const String _kSessionId = '18f43c';
const String _kEndpoint =
    'http://127.0.0.1:7457/ingest/6dc26a65-f9be-42f4-976e-f25462710aef';

void debugScrollLog({
  required String location,
  required String message,
  Map<String, dynamic>? data,
  String? hypothesisId,
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
  };
  unawaited(
    http
        .post(
          Uri.parse(_kEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': _kSessionId,
          },
          body: jsonEncode(payload),
        )
        .catchError((_) {}),
  );
}
// #endregion
