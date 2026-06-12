import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/circadian_schedule.dart';

typedef ArcGeometry = ({
  double startX,
  double endX,
  double horizonY,
  double controlX,
  double controlY,
});

class _SkyKeyframe {
  final double hour;
  final Color top;
  final Color bot;
  const _SkyKeyframe({
    required this.hour,
    required this.top,
    required this.bot,
  });
}

class _CueMarker {
  final DateTime time;
  final String label;
  final bool labelAbove;
  const _CueMarker({
    required this.time,
    required this.label,
    required this.labelAbove,
  });
}

class SkyPainter extends CustomPainter {
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime now;
  final CircadianSchedule schedule;

  const SkyPainter({
    required this.sunrise,
    required this.sunset,
    required this.now,
    required this.schedule,
  });

  static const List<_SkyKeyframe> _keyframes = [
    _SkyKeyframe(hour: 0,  top: Color(0xFF080818), bot: Color(0xFF110C34)),
    _SkyKeyframe(hour: 5,  top: Color(0xFF180C34), bot: Color(0xFF6B2D1E)),
    _SkyKeyframe(hour: 7,  top: Color(0xFF2B6CB0), bot: Color(0xFF63B3ED)),
    _SkyKeyframe(hour: 10, top: Color(0xFF2C5282), bot: Color(0xFF4299E1)),
    _SkyKeyframe(hour: 15, top: Color(0xFF2D4A8A), bot: Color(0xFF5A82C0)),
    _SkyKeyframe(hour: 17, top: Color(0xFF2A1650), bot: Color(0xFF5A3070)),
    _SkyKeyframe(hour: 19, top: Color(0xFF150C30), bot: Color(0xFF2A1848)),
    _SkyKeyframe(hour: 23, top: Color(0xFF080818), bot: Color(0xFF110C34)),
  ];

  ({Color top, Color bot}) _skyColors(double hourOfDay) {
    for (var i = 0; i < _keyframes.length - 1; i++) {
      final a = _keyframes[i];
      final b = _keyframes[i + 1];
      if (hourOfDay >= a.hour && hourOfDay < b.hour) {
        final t = (hourOfDay - a.hour) / (b.hour - a.hour);
        return (
          top: Color.lerp(a.top, b.top, t)!,
          bot: Color.lerp(a.bot, b.bot, t)!,
        );
      }
    }
    return (top: _keyframes.last.top, bot: _keyframes.last.bot);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hourOfDay = now.hour + now.minute / 60.0;
    final colors = _skyColors(hourOfDay);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors.top, colors.bot],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    final geo = _arcGeometry(size);
    _drawArc(canvas, geo);
    _drawCueMarkers(canvas, geo);
    _drawSun(canvas, geo);
  }

  ArcGeometry _arcGeometry(Size size) => (
        startX: size.width * 0.05,
        endX: size.width * 0.95,
        horizonY: size.height * 0.75,
        controlX: size.width * 0.5,
        controlY: size.height * 0.1,
      );

  void _drawArc(Canvas canvas, ArcGeometry geo) {
    final path = Path()
      ..moveTo(geo.startX, geo.horizonY)
      ..quadraticBezierTo(geo.controlX, geo.controlY, geo.endX, geo.horizonY);

    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, arcPaint);
  }

  void _drawCueMarkers(Canvas canvas, ArcGeometry geo) {
    final dayLength = sunset.difference(sunrise).inMinutes.toDouble();

    final markers = [
      _CueMarker(
        time: schedule.morningSunlightStart,
        label: _formatTime(schedule.morningSunlightStart),
        labelAbove: true,
      ),
      _CueMarker(
        time: schedule.afternoonSunlightStart,
        label: _formatTime(schedule.afternoonSunlightStart),
        labelAbove: true,
      ),
      _CueMarker(
        time: schedule.caffeineCutoff,
        label: _formatTime(schedule.caffeineCutoff),
        labelAbove: false,
      ),
      _CueMarker(
        time: schedule.dimLights,
        label: _formatTime(schedule.dimLights),
        labelAbove: false,
      ),
    ];

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (final marker in markers) {
      final minutes = marker.time.difference(sunrise).inMinutes.toDouble();
      final t = (minutes / dayLength).clamp(0.0, 1.0);

      final x = _quadraticBezierPoint(geo.startX, geo.controlX, geo.endX, t);
      final y = _quadraticBezierPoint(geo.horizonY, geo.controlY, geo.horizonY, t);

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
      _drawMarkerLabel(canvas, marker.label, x, y, marker.labelAbove);
    }
  }

  void _drawMarkerLabel(
      Canvas canvas, String text, double x, double y, bool above) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 9,
      ),
    )
      ..pushStyle(ui.TextStyle(color: Colors.white.withValues(alpha: 0.85)))
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 48));

    final labelX = x - 24;
    final labelY = above ? y - 16 : y + 6;

    canvas.drawParagraph(paragraph, Offset(labelX, labelY));
  }

  void _drawSun(Canvas canvas, ArcGeometry geo) {
    final dayLength = sunset.difference(sunrise).inMinutes.toDouble();
    final minutesSinceSunrise = now.difference(sunrise).inMinutes.toDouble();
    final t = (minutesSinceSunrise / dayLength).clamp(0.0, 1.0);

    final sunX = _quadraticBezierPoint(geo.startX, geo.controlX, geo.endX, t);
    final sunY = _quadraticBezierPoint(geo.horizonY, geo.controlY, geo.horizonY, t);

    final solidPaint = Paint()..color = const Color(0xFFFDB813);
    final glowPaint = Paint()
      ..color = const Color(0xFFFDB813).withValues(alpha: 0.3);

    canvas.drawCircle(Offset(sunX, sunY), 16, glowPaint);
    canvas.drawCircle(Offset(sunX, sunY), 10, solidPaint);
  }

  double _quadraticBezierPoint(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$h:$m$period';
  }

  @override
  bool shouldRepaint(SkyPainter oldDelegate) =>
      oldDelegate.now != now ||
      oldDelegate.sunrise != sunrise ||
      oldDelegate.sunset != sunset ||
      oldDelegate.schedule != schedule;
}
