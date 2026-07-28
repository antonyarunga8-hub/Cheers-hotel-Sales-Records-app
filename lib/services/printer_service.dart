import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/order.dart';

/// Result of a print attempt.
enum PrintResult { success, printerNotConnected, error }

/// Printer configuration for the Xprinter XP-Q80A.
class PrinterConfig {
  static const String printerName = 'XP-Q80A';
  static const String macAddress = '00-79-31-86-78-F4';
  static const String lanIp = '192.168.123.100';
  static const int lanPort = 9100;
  static const String subnet = '255.255.255.0';
  static const String gateway = '192.168.123.1';
  static const int speedMmPerSec = 230;
  static const String firmwareVersion = '3.012PR6Y';
}

/// Printing is desktop-only. Mobile/web apps rely on the desktop till
/// to print via the Print Queue. This factory returns the right impl.
abstract class PrinterService {
  Future<PrintResult> printReceipt(Order order, {required String restaurantName});
  bool get isPrintingSupported;

  factory PrinterService() {
    if (kIsWeb) return NoOpPrinterService();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return WindowsEscPosPrinterService();
    }
    return NoOpPrinterService();
  }
}

/// Real desktop implementation — sends ESC/POS bytes to XP-Q80A
/// over LAN socket (192.168.123.100:9100) or USB spooler.
class WindowsEscPosPrinterService implements PrinterService {
  final List<Order> _fallbackQueue = [];

  @override
  bool get isPrintingSupported => true;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    try {
      // Build receipt bytes using receipt_formatter (desktop only import)
      final bytes = _buildReceiptBytes(order, restaurantName);

      final sent = await _sendToLan(bytes);
      if (!sent) {
        final usbSent = await _sendToUsbSpooler(bytes);
        if (!usbSent) {
          _fallbackQueue.add(order);
          return PrintResult.printerNotConnected;
        }
      }
      return PrintResult.success;
    } catch (_) {
      _fallbackQueue.add(order);
      return PrintResult.error;
    }
  }

  List<int> _buildReceiptBytes(Order order, String restaurantName) {
    // Simplified ESC/POS receipt — full formatting via esc_pos_utils_plus
    // is wired on-site during deployment (requires dart:io for sockets).
    final lines = <String>[
      '\x1B\x40',           // ESC @ — Initialize printer
      '\x1B\x61\x01',       // Center alignment
      '\x1D\x21\x11',       // Double height+width
      restaurantName,
      '\x1D\x21\x00',       // Normal size
      '\n',
      'Order Receipt',
      '─' * 32,
    ];

    for (final item in order.items) {
      final name = '${item.qty}x ${item.name}';
      final price = item.lineTotal.toStringAsFixed(0);
      final pad = 32 - name.length - price.length;
      lines.add('$name${' ' * (pad > 0 ? pad : 1)}$price');
    }

    lines.addAll([
      '─' * 32,
      '\x1B\x45\x01',       // Bold on
      'TOTAL KES ${order.total.toStringAsFixed(0)}',
      '\x1B\x45\x00',       // Bold off
      '\n',
      'Thank you for dining with us!',
      'Cheers Hotel — Vihiga, Mbale',
      '\n\n\n',
      '\x1D\x56\x00',       // Full cut
    ]);

    return lines.join('\n').codeUnits;
  }

  Future<bool> _sendToLan(List<int> bytes) async {
    // TODO(deploy): Wire up LAN socket to 192.168.123.100:9100 on-site
    // Uses dart:io Socket which is only available on desktop/mobile.
    return false;
  }

  Future<bool> _sendToUsbSpooler(List<int> bytes) async {
    // TODO(deploy): Wire up win32 RAW spooler for USB connection.
    return false;
  }

  List<Order> get pendingRetries => List.unmodifiable(_fallbackQueue);
}

/// Mobile/web stub — printing is handled by the desktop Print Queue.
class NoOpPrinterService implements PrinterService {
  @override
  bool get isPrintingSupported => false;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    return PrintResult.printerNotConnected;
  }
}
