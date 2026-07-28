import 'package:intl/intl.dart';

import '../models/order.dart';
import '../models/payment_method.dart';

/// Builds a plain-text receipt string for display previews and
/// non-ESC/POS output. The actual ESC/POS byte stream for the
/// Xprinter XP-Q80A is generated in WindowsEscPosPrinterService.
class ReceiptFormatter {
  /// Returns a human-readable receipt string (for on-screen preview
  /// and non-thermal output).
  static String format(
    Order order,
    String restaurantName, {
    int? orderNumber,
  }) {
    final buf = StringBuffer();
    final width = 32;

    buf.writeln(restaurantName.padLeft((width + restaurantName.length) ~/ 2));
    if (orderNumber != null) {
      final num = 'Order #${orderNumber.toString().padLeft(3, '0')}';
      buf.writeln(num.padLeft((width + num.length) ~/ 2));
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.timestamp);
    buf.writeln(dateStr.padLeft((width + dateStr.length) ~/ 2));

    final sourceLabel =
        order.source == OrderSource.mobile ? 'Mobile Order' : 'Till Order';
    buf.writeln(sourceLabel.padLeft((width + sourceLabel.length) ~/ 2));

    buf.writeln('─' * width);

    for (final line in order.items) {
      final name = '${line.qty}x ${line.name}';
      final price = line.lineTotal.toStringAsFixed(0);
      final pad = width - name.length - price.length;
      buf.writeln('$name${' ' * (pad > 0 ? pad : 1)}$price');
    }

    buf.writeln('─' * width);

    final totalLabel = 'TOTAL (KES)';
    final totalValue = order.total.toStringAsFixed(0);
    final totalPad = width - totalLabel.length - totalValue.length;
    buf.writeln('$totalLabel${' ' * (totalPad > 0 ? totalPad : 1)}$totalValue');

    final paymentLabel = order.paymentMethod == PaymentMethod.mpesa
        ? 'Paid via M-Pesa'
        : 'Paid in Cash';
    buf.writeln(paymentLabel.padLeft((width + paymentLabel.length) ~/ 2));

    buf.writeln();
    const thanks = 'Thank you for dining with us!';
    buf.writeln(thanks.padLeft((width + thanks.length) ~/ 2));
    const footer = 'Cheers Hotel — Vihiga, Mbale';
    buf.writeln(footer.padLeft((width + footer.length) ~/ 2));

    return buf.toString();
  }
}
