import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/flow.dart';

class FlowDetailScreen extends StatelessWidget {
  final Flow flow;

  const FlowDetailScreen({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(flow.host, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(tabs: [Tab(text: 'Request'), Tab(text: 'Response')]),
        ),
        body: TabBarView(
          children: [
            _RequestTab(flow: flow),
            _ResponseTab(flow: flow),
          ],
        ),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  final Flow flow;
  const _RequestTab({required this.flow});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionHeader(text: '${flow.method} ${flow.url}', onCopy: flow.url),
        const SizedBox(height: 12),
        _SectionLabel('Headers'),
        _HeadersBlock(headers: flow.reqHeaders),
        const SizedBox(height: 16),
        _SectionLabel('Body'),
        _BodyBlock(body: flow.reqBody),
      ],
    );
  }
}

class _ResponseTab extends StatelessWidget {
  final Flow flow;
  const _ResponseTab({required this.flow});

  @override
  Widget build(BuildContext context) {
    if (flow.isError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          flow.respBody ?? 'Request errored, no response received.',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _SectionHeader(
          text: 'Status ${flow.respStatus}${flow.durationMs != null ? '  ·  ${flow.durationMs}ms' : ''}',
          onCopy: '${flow.respStatus}',
        ),
        const SizedBox(height: 12),
        _SectionLabel('Headers'),
        _HeadersBlock(headers: flow.respHeaders),
        const SizedBox(height: 16),
        _SectionLabel('Body'),
        _BodyBlock(body: flow.respBody),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final String onCopy;
  const _SectionHeader({required this.text, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: onCopy));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)));
          },
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
      );
}

class _HeadersBlock extends StatelessWidget {
  final Map<String, dynamic> headers;
  const _HeadersBlock({required this.headers});

  @override
  Widget build(BuildContext context) {
    if (headers.isEmpty) return const Text('(none)', style: TextStyle(color: Colors.grey));
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(
        headers.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}

class _BodyBlock extends StatelessWidget {
  final String? body;
  const _BodyBlock({required this.body});

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.isEmpty) {
      return const Text('(empty)', style: TextStyle(color: Colors.grey));
    }
    return Container(
      padding: const EdgeInsets.all(8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(body!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
    );
  }
}
