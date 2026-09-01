import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_application_1/core/persistence/canonical_json.dart';

abstract interface class ChecksumService {
  String checksumCanonical(Object? value);
}

class Sha256ChecksumService implements ChecksumService {
  const Sha256ChecksumService();

  @override
  String checksumCanonical(Object? value) {
    final canonical = CanonicalJson.encode(value);
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}
