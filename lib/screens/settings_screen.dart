import 'package:flutter/material.dart';

/// Settings screen for on-site configuration (doc §16).
/// V1: printer IP/name, app info. V2: staff accounts, themes.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _printerIpCtrl = TextEditingController(text: '192.168.1.100');
  final _printerNameCtrl = TextEditingController(text: 'XP-Q80A');

  @override
  void dispose() {
    _printerIpCtrl.dispose();
    _printerNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Printer settings
          Text('Printer Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _printerNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Printer Name (Windows share)',
                      helperText: 'e.g., XP-Q80A',
                      prefixIcon: Icon(Icons.print),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _printerIpCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Printer LAN IP (fallback)',
                      helperText: 'e.g., 192.168.1.100',
                      prefixIcon: Icon(Icons.lan),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO(deploy): Persist to SharedPreferences and
                      // pass to PrinterService on next print call.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Printer settings saved.')),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App info
          Text('About',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'App', value: 'Cheers Hotel — Sales & Records'),
                  _InfoRow(label: 'Version', value: '1.0.0 (V1)'),
                  _InfoRow(label: 'Printer Model', value: 'Xprinter XP-Q80A'),
                  _InfoRow(label: 'Interface', value: 'USB + LAN (port 9100)'),
                  _InfoRow(label: 'Paper Width', value: '80mm'),
                  const Divider(height: 24),
                  _InfoRow(label: 'Developer', value: 'Antony Arunga'),
                  _InfoRow(label: 'Client', value: 'Enose Mugalla — Cheers Hotel'),
                  _InfoRow(label: 'Doc Version', value: '3.0 — July 2026'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
