import 'package:flutter/material.dart';

enum CueStatus { passed, active, upcoming }

class CueCard extends StatefulWidget {
  final String icon;
  final String label;
  final String timeRange;
  final CueStatus status;
  final String scienceExplanation;
  final DateTime cueTime;
  final DateTime now;

  const CueCard({
    super.key,
    required this.icon,
    required this.label,
    required this.timeRange,
    required this.status,
    required this.scienceExplanation,
    required this.cueTime,
    required this.now,
  });

  @override
  State<CueCard> createState() => _CueCardState();
}

class _CueCardState extends State<CueCard> {
  bool _infoOpen = false;

  String _statusText() {
    switch (widget.status) {
      case CueStatus.passed:
        return 'Passed';
      case CueStatus.active:
        return 'Now';
      case CueStatus.upcoming:
        final diff = widget.cueTime.difference(widget.now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        if (hours > 0) return 'In ${hours}h';
        return 'In ${minutes}m';
    }
  }

  Color _statusTextColor() {
    return switch (widget.status) {
      CueStatus.active => const Color(0xFFBA7517),
      CueStatus.passed => Colors.grey,
      CueStatus.upcoming => Colors.black54,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status == CueStatus.active;
    final isPassed = widget.status == CueStatus.passed;

    return Opacity(
      opacity: isPassed ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFAEEDA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFBA7517) : Colors.grey.shade200,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.timeRange} · ${_statusText()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _statusTextColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _infoOpen ? Icons.info : Icons.info_outline,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _infoOpen = !_infoOpen),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            if (_infoOpen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Text(
                  widget.scienceExplanation,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
