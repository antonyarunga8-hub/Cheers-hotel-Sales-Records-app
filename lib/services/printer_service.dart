import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/order.dart';
import '../utils/receipt_formatter.dart';

/// Result of a print attempt, surfaced to the UI so the till operator can
/// retry/reprint (doc §7.3 — handle printer-not-connected gracefully).
enum PrintResult { success, printerNotConnected, error }

/// Printing is desktop-only — the mobile app never talks to the printer
/// directly (doc §5, §7.3). This abstract service lets screens call
/// `printReceipt` unconditionally; the mobile build gets a no-op stub.
abstract class PrinterService {
  Future<PrintResult> printReceipt(Order order, {required String restaurantName});

  /// True only on the desktop build where a printer could plausibly exist.
  bool get isPrintingSupported;

  factory PrinterService() {
    if (kIsWeb) return NoOpPrinterService();
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return WindowsEscPosPrinterService();
    }
    return NoOpPrinterService();
  }
}

/// Real desktop implementation. Sends ESC/POS-formatted bytes to the
/// Xprinter XP-Q80A over USB (primary) via the Windows raw print spooler,
/// with a LAN socket (port 9100) fallback per doc §5 and §16.
class WindowsEscPosPrinterService implements PrinterService {
  static const String usbPrinterName = 'XP-Q80A';
  static const String lanFallbackIp = '192.168.1.100';
  static const int lanFallbackPort = 9100;

  final List<Order> _fallbackQueue = [];

  @override
  bool get isPrintingSupported => true;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    try {
      final bytes = ReceiptFormatter.format(order, restaurantName);

      final sent = await _sendToUsbSpooler(bytes);
      if (!sent) {
        final lanSent = await _sendToLan(bytes);
        if (!lanSent) {
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

  List<Order> get pendingRetries => List.unmodifiable(_fallbackQueue);

  Future<void> retryQueued({required String restaurantName}) async {
    final queued = List<Order>.from(_fallbackQueue);
    for (final order in queued) {
      final result = await printReceipt(order, restaurantName: restaurantName);
      if (result == PrintResult.success) {
        _fallbackQueue.remove(order);
      }
    }
  }

  Future<bool> _sendToUsbSpooler(List<int> bytes) async {
    // TODO(install): Wire up win32 RAW spooler on-site.
    return false;
  }

  Future<bool> _sendToLan(List<int> bytes) async {
    // TODO(install): Wire up LAN socket to printer IP on-site.
    return false;
  }
}

/// Mobile, web, and any non-Windows build. Printing is never attempted —
/// the mobile/web app relies on the desktop till to print every order.
class NoOpPrinterService implements PrinterService {
  @override
  bool get isPrintingSupported => false;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    return PrintResult.printerNotConnected;
  }
}
