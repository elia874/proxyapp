import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart' hide Flow;
import 'package:intl/intl.dart';

import '../models/flow.dart';

class FlowTile extends StatelessWidget {
  final Flow flow;
  final VoidCallback onTap;

  const FlowTile({super.key, required this.flow, required this.onTap});

  Color _statusColor(BuildContext context) {
    if (flow.isError) return Colors.grey;
    if (flow.isClientOrServerError) return Colors.red;
    if (flow.isSuccess) return Colors.green;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = flow.isError ? 'ERR' : '${flow.respStatus}';
    final time = DateFormat.Hms().format(flow.timestamp);

    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 48,
        child: Text(
          statusLabel,
          style: TextStyle(
            color: _statusColor(context),
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
      title: Text(
        flow.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
      subtitle: Text(
        '${flow.method}  ·  ${flow.host}  ·  $time'
        '${flow.durationMs != null ? '  ·  ${flow.durationMs}ms' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      dense: true,
    );
  }
}
