import 'package:flutter/material.dart' hide Flow;

import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '8000');
  final _tokenCtrl = TextEditingController();
  bool _useTls = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _settings.load();
    _hostCtrl.text = s['host'] as String;
    _portCtrl.text = '${s['port']}';
    _tokenCtrl.text = s['token'] as String;
    _useTls = s['useTls'] as bool;
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final port = int.tryParse(_portCtrl.text.trim()) ?? 8000;
    await _settings.save(
      host: _hostCtrl.text.trim(),
      port: port,
      token: _tokenCtrl.text.trim(),
      useTls: _useTls,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('VPS Connection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: 'VPS host / IP',
              hintText: '144.172.109.109',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Backend port (FastAPI, not mitmproxy)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tokenCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Control token'),
          ),
          SwitchListTile(
            value: _useTls,
            onChanged: (v) => setState(() => _useTls = v),
            title: const Text('Use TLS (wss/https)'),
            subtitle: const Text('Enable once the backend is behind a reverse proxy with a cert'),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Save & Connect'),
          )),
        ],
      ),
    );
  }
}
