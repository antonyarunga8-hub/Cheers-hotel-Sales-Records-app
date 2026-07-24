import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/connectivity_monitor.dart';

/// Reusable offline notification banner.
/// Shows a warning strip when the device loses connectivity.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityMonitor>();

    if (connectivity.isOnline) return const SizedBox.shrink();

    return MaterialBanner(
      content: const Text(
        'You are offline. Orders will sync when connection returns.',
      ),
      leading: const Icon(Icons.cloud_off, color: Colors.orange),
      backgroundColor: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: const [SizedBox.shrink()],
    );
  }
}
