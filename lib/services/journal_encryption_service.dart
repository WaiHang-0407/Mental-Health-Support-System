import 'package:encrypt/encrypt.dart';

class JournalEncryptionService {
  static final _key = Key.fromUtf8(
    '12345678901234567890123456789012',
  ); // 32 chars
  static final _iv = IV.fromUtf8('1234567890123456'); // 16 chars

  final Encrypter _encrypter = Encrypter(AES(_key));

  String encryptText(String plainText) {
    return _encrypter.encrypt(plainText, iv: _iv).base64;
  }

  String decryptText(String encryptedText) {
    return _encrypter.decrypt64(encryptedText, iv: _iv);
  }
}