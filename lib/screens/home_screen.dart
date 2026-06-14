import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/circadian_schedule.dart';
import '../viewmodels/schedule_viewmodel.dart';
import 'painters/sky_painter.dart';
import 'settings_screen.dart';
import 'widgets/cue_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final ScheduleViewModel _viewModel;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = GetIt.instance<ScheduleViewModel>();
    _viewModel.loadSchedule();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.loadSchedule();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  CueStatus _cueStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isAfter(end)) return CueStatus.passed;
    if (now.isAfter(start)) return CueStatus.active;
    return CueStatus.upcoming;
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${_fmt(start)} – ${_fmt(end)}';
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$h:$m$period';
  }

  List<Widget> _buildCueCards(CircadianSchedule schedule) {
    final now = DateTime.now();
    const halfHour = Duration(minutes: 30);

    return [
      CueCard(
        icon: '☀️',
        label: 'Morning sunlight',
        timeRange: _formatTimeRange(
          schedule.morningSunlightStart,
          schedule.morningSunlightEnd,
        ),
        status: _cueStatus(
          schedule.morningSunlightStart,
          schedule.morningSunlightEnd,
        ),
        scienceExplanation:
            'Morning sunlight triggers a cortisol pulse that sets your '
            'circadian clock, boosts alertness, and anchors your sleep '
            'timing for the night ahead. Aim for 10–20 minutes outside '
            'within the first hour of waking.',
        cueTime: schedule.morningSunlightStart,
        now: now,
      ),
      CueCard(
        icon: '☕',
        label: 'Caffeine cutoff',
        timeRange: _fmt(schedule.caffeineCutoff),
        status: _cueStatus(
          schedule.caffeineCutoff.subtract(halfHour),
          schedule.caffeineCutoff.add(halfHour),
        ),
        scienceExplanation:
            'Caffeine blocks adenosine receptors, delaying the sleepiness '
            'signal. With a ~6-hour half-life, caffeine consumed too late '
            'reduces deep sleep even if you fall asleep on time. Cutting '
            'off 4 hours before sunset keeps sleep architecture intact.',
        cueTime: schedule.caffeineCutoff,
        now: now,
      ),
      CueCard(
        icon: '🌤️',
        label: 'Afternoon sunlight',
        timeRange: _formatTimeRange(
          schedule.afternoonSunlightStart,
          schedule.afternoonSunlightEnd,
        ),
        status: _cueStatus(
          schedule.afternoonSunlightStart,
          schedule.afternoonSunlightEnd,
        ),
        scienceExplanation:
            'Late-afternoon light recalibrates your circadian phase and '
            'builds a "second anchor" for your clock. It also buffers '
            'against the phase-advancing effect of artificial light in '
            'the evening, making you less sensitive to screens after dark.',
        cueTime: schedule.afternoonSunlightStart,
        now: now,
      ),
      CueCard(
        icon: '🌙',
        label: 'Dim the lights',
        timeRange: _fmt(schedule.dimLights),
        status: _cueStatus(
          schedule.dimLights.subtract(halfHour),
          schedule.dimLights.add(halfHour),
        ),
        scienceExplanation:
            'Bright light in the 2 hours before bed suppresses melatonin '
            'by up to 50%. Dimming overhead lights and switching to warm, '
            'low sources signals your brain that night is approaching and '
            'accelerates the melatonin rise needed for deep sleep.',
        cueTime: schedule.dimLights,
        now: now,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: ValueListenableBuilder<ScheduleState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) {
          return switch (state) {
            ScheduleLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ScheduleError(:final message) => Center(child: Text(message)),
            ScheduleSuccess(:final schedule, :final city) => ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: SkyPainter(
                            sunrise: schedule.sunrise,
                            sunset: schedule.sunset,
                            now: DateTime.now(),
                            schedule: schedule,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              city ?? 'Unknown location',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFFF5F5F7)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildCueCards(schedule),
                const SizedBox(height: 24),
              ],
            ),
          };
        },
      ),
    );
  }
}
