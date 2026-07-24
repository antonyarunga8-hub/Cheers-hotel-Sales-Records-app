import 'dart:io' show Platform;

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
    if (Platform.isWindows) {
      return WindowsEscPosPrinterService();
    }
    return NoOpPrinterService();
  }
}

/// Real desktop implementation. Sends ESC/POS-formatted bytes to the
/// Xprinter XP-Q80A over USB (primary) via the Windows raw print spooler,
/// with a LAN socket (port 9100) fallback per doc §5 and §16.
///
/// NOTE: the raw win32 spooler call and the LAN socket fallback are left
/// as clearly marked TODOs — they depend on the exact printer share name
/// / IP configured on-site, which should be set once during install.
class WindowsEscPosPrinterService implements PrinterService {
  // Configure these once during on-site setup.
  static const String usbPrinterName = 'XP-Q80A'; // Windows printer share name
  static const String lanFallbackIp = '192.168.1.100'; // set to printer's IP
  static const int lanFallbackPort = 9100;

  final List<Order> _fallbackQueue = [];

  @override
  bool get isPrintingSupported => true;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    try {
      final bytes = ReceiptFormatter.format(order, restaurantName);

      // TODO(install): wire up the actual win32 RAW spooler call here, e.g.
      //   OpenPrinter(usbPrinterName) -> StartDocPrinter -> WritePrinter(bytes)
      // or fall back to a raw TCP write to lanFallbackIp:lanFallbackPort.
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

  /// Orders that failed to print and are waiting for retry/reprint.
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
    // Placeholder — returns false until wired to win32 spooler on-site.
    return false;
  }

  Future<bool> _sendToLan(List<int> bytes) async {
    // Placeholder — returns false until the printer's LAN IP is confirmed.
    return false;
  }
}

/// Mobile (and any non-Windows) build. Printing is never attempted here —
/// the mobile app relies on the desktop till to print every order.
class NoOpPrinterService implements PrinterService {
  @override
  bool get isPrintingSupported => false;

  @override
  Future<PrintResult> printReceipt(Order order,
      {required String restaurantName}) async {
    return PrintResult.printerNotConnected;
  }
}
