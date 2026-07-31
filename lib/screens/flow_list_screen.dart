import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/flow.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/flow_tile.dart';
import 'flow_detail_screen.dart';
import 'settings_screen.dart';

class FlowListScreen extends StatefulWidget {
  const FlowListScreen({super.key});

  @override
  State<FlowListScreen> createState() => _FlowListScreenState();
}

class _FlowListScreenState extends State<FlowListScreen> {
  final _settingsService = SettingsService();
  ApiService? _api;
  StreamSubscription? _wsSub;

  final List<Flow> _flows = [];
  String? _hostFilter;
  bool _loading = true;
  String? _error;
  bool _live = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final configured = await _settingsService.isConfigured();
    if (!configured) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      if (ok != true) {
        setState(() {
          _loading = false;
          _error = 'Not configured';
        });
        return;
      }
    }
    await _connect();
  }

  Future<void> _connect() async {
    _wsSub?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _live = false;
    });

    final s = await _settingsService.load();
    final api = ApiService(
      host: s['host'] as String,
      port: s['port'] as int,
      controlToken: s['token'] as String,
      useTls: s['useTls'] as bool,
    );
    _api = api;

    try {
      final history = await api.fetchFlows(limit: 200, hostFilter: _hostFilter);
      setState(() {
        _flows
          ..clear()
          ..addAll(history.reversed); // newest first
        _loading = false;
      });
    } on ApiAuthException {
      setState(() {
        _loading = false;
        _error = 'Control token rejected — check Settings';
      });
      return;
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not reach backend: $e';
      });
      return;
    }

    _listenLive(api);
  }

  void _listenLive(ApiService api) {
    final channel = api.connectStream();
    _wsSub = channel.stream.listen(
      (raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        if (msg['type'] != 'flow') return;
        final flow = Flow.fromJson(msg['data'] as Map<String, dynamic>);
        if (_hostFilter != null && _hostFilter!.isNotEmpty && !flow.host.contains(_hostFilter!)) {
          return;
        }
        setState(() {
          _flows.insert(0, flow);
          if (_flows.length > 1000) _flows.removeLast();
          _live = true;
        });
      },
      onError: (_) => setState(() => _live = false),
      onDone: () => setState(() => _live = false),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _openSettings() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (ok == true) _connect();
  }

  void _showFilterDialog() {
    final ctrl = TextEditingController(text: _hostFilter);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by host'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. discover.com'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hostFilter = null);
              _connect();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _hostFilter = ctrl.text.trim());
              _connect();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Live Traffic'),
            const SizedBox(width: 8),
            if (_live)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _connect, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_flows.isEmpty) {
      return const Center(child: Text('No traffic captured yet — browse on your phone.'));
    }
    return RefreshIndicator(
      onRefresh: _connect,
      child: ListView.separated(
        itemCount: _flows.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final flow = _flows[i];
          return FlowTile(
            flow: flow,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FlowDetailScreen(flow: flow)),
            ),
          );
        },
      ),
    );
  }
}
