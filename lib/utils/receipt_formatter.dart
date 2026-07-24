import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/payment_method.dart';

/// Builds the ESC/POS byte stream for a printed receipt: restaurant name,
/// order number, itemized list, total, payment method, date/time,
/// and a "Thank you" footer (doc §7.3).
class ReceiptFormatter {
  static List<int> format(
    Order order,
    String restaurantName, {
    int? orderNumber,
  }) {
    final profile = CapabilityProfile.getDefault();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    // Header — restaurant name
    bytes.addAll(generator.text(
      restaurantName,
      styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2),
    ));

    // Order number (if available)
    if (orderNumber != null) {
      bytes.addAll(generator.text(
        'Order #${orderNumber.toString().padLeft(3, '0')}',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
    }

    // Date and time
    bytes.addAll(generator.text(
      DateFormat('dd MMM yyyy, HH:mm').format(order.timestamp),
      styles: const PosStyles(align: PosAlign.center),
    ));

    // Source badge
    final sourceLabel =
        order.source == OrderSource.mobile ? 'Mobile Order' : 'Till Order';
    bytes.addAll(generator.text(
      sourceLabel,
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.hr());

    // Line items
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

    // Total
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

    // Payment method
    final paymentLabel = order.paymentMethod == PaymentMethod.mpesa
        ? 'Paid via M-Pesa'
        : 'Paid in Cash';
    bytes.addAll(generator.text(
      paymentLabel,
      styles: const PosStyles(align: PosAlign.center),
    ));

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      'Thank you for dining with us!',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      'Cheers Hotel — Nairobi',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.cut());

    return bytes;
  }
}
