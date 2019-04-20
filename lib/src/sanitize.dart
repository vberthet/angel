import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';

final Map<Pattern, String> defaultSanitizers = {
  RegExp(r'<\s*s\s*c\s*r\s*i\s*p\s*t\s*>.*<\s*\/\s*s\s*c\s*r\s*i\s*p\s*t\s*>',
      caseSensitive: false): ''
};

/// Mitigates XSS risk by sanitizing user HTML input.
///
/// You can also provide a Map of patterns to [replace].
///
/// You can sanitize the [body] or [query] (both `true` by default).
RequestHandler sanitizeHtmlInput(
    {bool body = true,
    bool query = true,
    Map<Pattern, String> replace = const {}}) {
  var sanitizers = Map<Pattern, String>.from(defaultSanitizers)
    ..addAll(replace ?? {});

  return (req, res) async {
    if (body) {
      await req.parseBody();
      _sanitizeMap(req.bodyAsMap, sanitizers);
    }

    if (query) _sanitizeMap(req.queryParameters, sanitizers);
    return true;
  };
}

_sanitize(v, Map<Pattern, String> sanitizers) {
  if (v is String) {
    var str = v;

    sanitizers.forEach((needle, replace) {
      str = str.replaceAll(needle, replace);
    });

    return htmlEscape.convert(str);
  } else if (v is Map) {
    _sanitizeMap(v, sanitizers);
    return v;
  } else if (v is Iterable) {
    bool isList = v is List;
    var mapped = v.map((x) => _sanitize(x, sanitizers));
    return isList ? mapped.toList() : mapped;
  } else
    return v;
}

void _sanitizeMap(Map data, Map<Pattern, String> sanitizers) {
  data.forEach((k, v) {
    data[k] = _sanitize(v, sanitizers);
  });
}
