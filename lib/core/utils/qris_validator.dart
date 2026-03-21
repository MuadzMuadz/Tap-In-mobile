/// QRIS EMV string validator — mirrors the web version logic
class QrisValidator {
  QrisValidator._();

  static bool validate(String qrisString) {
    final s = qrisString.trim();
    if (s.length < 20) return false;
    if (!s.startsWith('000201')) return false;
    if (!s.toUpperCase().endsWith('6304')) {
      // Must end with checksum tag 63 + 04 + 4-char CRC
      final idx = s.length - 8;
      if (idx < 0) return false;
      if (!s.substring(idx, idx + 4).toUpperCase().startsWith('6304')) {
        return false;
      }
    }
    return true;
  }
}
