import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class EncryptionService {
  static Uint8List deriveKey(String jwt) {
    final digest = SHA256Digest();
    final input = Uint8List.fromList(utf8.encode(jwt));
    final output = Uint8List(digest.digestSize);
    digest.update(input, 0, input.length);
    digest.doFinal(output, 0);
    return output;
  }

  static Map<String, String> encrypt(String plaintext, Uint8List key) {
    final iv = Uint8List.fromList(
      List.generate(12, (_) => Random.secure().nextInt(256)),
    );
    final input = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
      );

    final output = Uint8List(cipher.getOutputSize(input.length));
    final len1 = cipher.processBytes(input, 0, input.length, output, 0);
    final len2 = cipher.doFinal(output, len1);

    final ciphertext = Uint8List.sublistView(output, 0, len1 + len2);

    return {
      'iv': base64Encode(iv),
      'data': base64Encode(ciphertext),
    };
  }

  static String decrypt(Map<String, dynamic> payload, Uint8List key) {
    final iv = Uint8List.fromList(base64Decode(payload['iv'] as String));
    final ciphertextWithTag =
        Uint8List.fromList(base64Decode(payload['data'] as String));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
      );

    final input = ciphertextWithTag;
    final output = Uint8List(cipher.getOutputSize(input.length));
    final len1 = cipher.processBytes(input, 0, input.length, output, 0);
    final len2 = cipher.doFinal(output, len1);

    final plaintext = Uint8List.sublistView(output, 0, len1 + len2);
    return utf8.decode(plaintext);
  }
}
