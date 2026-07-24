import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';

/// Builds the ESC/POS byte stream for a printed receipt: restaurant name,
/// itemized list, total, date/time, and a "Thank you" footer (doc §7.3).
class ReceiptFormatter {
  static List<int> format(Order order, String restaurantName) {
    final profile = CapabilityProfile.getDefault();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.text(
      restaurantName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      DateFormat('dd MMM yyyy, HH:mm').format(order.timestamp),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    for (final line in order.items) {
      bytes.addAll(generator.row([
        PosColumn(text: '${line.qty}x ${line.name}', width: 8),
        PosColumn(
          text: line.lineTotal.toStringAsFixed(0),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(
        text: 'TOTAL (KES)',
        width: 8,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: order.total.toStringAsFixed(0),
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Thank you for dining with us!',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
