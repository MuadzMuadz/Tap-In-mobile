/// Dynamic QRIS generator — EMV QR Code standard (Bank Indonesia)
/// Ported from kasir-in/src/lib/qris.ts
class QrisGenerator {
  QrisGenerator._();

  /// Generate a dynamic QRIS string with embedded transaction amount.
  /// Returns null if [staticQris] is empty or invalid.
  static String? generate(String staticQris, double amount) {
    final s = staticQris.trim();
    if (s.isEmpty) return null;

    // Remove the CRC checksum (last 8 chars: "6304XXXX")
    final withoutCrc = _removeCrc(s);
    if (withoutCrc == null) return null;

    // 1. Change Point of Initiation Method from "11" (static) to "12" (dynamic)
    var result = withoutCrc.replaceFirst('010211', '010212');

    // 2. Inject transaction amount (tag 54)
    final amountStr = _formatAmount(amount);
    final amountField = '54${_pad(amountStr.length)}$amountStr';

    // Insert before tag 58 (country code) if present, else before 63 (CRC placeholder)
    final insertBefore = result.contains('5802') ? '5802' : '6304';
    result = result.replaceFirst(insertBefore, '$amountField$insertBefore');

    // 3. Append CRC placeholder and compute checksum
    result += '6304';
    final crc = _crc16(result);
    result += crc;

    return result;
  }

  static String? _removeCrc(String s) {
    // Find "6304" near the end and strip it + 4-char checksum
    final idx = s.lastIndexOf('6304');
    if (idx == -1) return null;
    return s.substring(0, idx);
  }

  static String _formatAmount(double amount) {
    // EMV amount: no currency symbol, no thousands separator
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  static String _pad(int length) {
    return length.toString().padLeft(2, '0');
  }

  /// CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF)
  static String _crc16(String data) {
    int crc = 0xFFFF;
    for (final char in data.codeUnits) {
      crc ^= char << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
