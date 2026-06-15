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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1F5C),
      body: ValueListenableBuilder<ScheduleState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) {
          return switch (state) {
            ScheduleLoading() => Container(
              color: const Color(0xFF0F1F5C),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFDB813),
                ),
              ),
            ),
            ScheduleError(:final message) => Container(
              color: const Color(0xFF0F1F5C),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, color: Colors.white54, size: 48),
                  const SizedBox(height: 24),
                  const Text(
                    'Could not load schedule',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _viewModel.loadSchedule(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDB813),
                      foregroundColor: const Color(0xFF0F1F5C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
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
                        height: 60,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF0F1F5C)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 0),
                _CueCardList(schedule: schedule),
                const SizedBox(height: 24),
              ],
            ),
          };
        },
      ),
    );
  }
}

class _CueCardList extends StatefulWidget {
  final CircadianSchedule schedule;

  const _CueCardList({required this.schedule});

  @override
  State<_CueCardList> createState() => _CueCardListState();
}

class _CueCardListState extends State<_CueCardList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  CueStatus _cueStatus(DateTime start, DateTime end) {
    final now = DateTime.now();
    if (now.isAfter(end)) return CueStatus.passed;
    if (now.isAfter(start)) return CueStatus.active;
    return CueStatus.upcoming;
  }

  String _fmt(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'am' : 'pm';
    return '$h:$m$period';
  }

  String _formatTimeRange(DateTime start, DateTime end) =>
      '${_fmt(start)} – ${_fmt(end)}';

  Widget _animated(int index, Widget child) {
    final anim = CurvedAnimation(
      parent: _animController,
      curve: Interval(index * 0.15, index * 0.15 + 0.4, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: anim,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 30 * (1 - anim.value)),
          child: child,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    final now = DateTime.now();
    const halfHour = Duration(minutes: 30);

    final cards = [
      CueCard(
        icon: '☀️',
        label: 'Morning sunlight',
        timeRange: _formatTimeRange(s.morningSunlightStart, s.morningSunlightEnd),
        status: _cueStatus(s.morningSunlightStart, s.morningSunlightEnd),
        scienceExplanation:
            'Morning sunlight triggers a cortisol pulse that sets your '
            'circadian clock, boosts alertness, and anchors your sleep '
            'timing for the night ahead. Aim for 10–20 minutes outside '
            'within the first hour of waking.',
        cueTime: s.morningSunlightStart,
        now: now,
      ),
      CueCard(
        icon: '☕',
        label: 'Caffeine cutoff',
        timeRange: _fmt(s.caffeineCutoff),
        status: _cueStatus(
          s.caffeineCutoff.subtract(halfHour),
          s.caffeineCutoff.add(halfHour),
        ),
        scienceExplanation:
            'Caffeine blocks adenosine receptors, delaying the sleepiness '
            'signal. With a ~6-hour half-life, caffeine consumed too late '
            'reduces deep sleep even if you fall asleep on time. Cutting '
            'off 4 hours before sunset keeps sleep architecture intact.',
        cueTime: s.caffeineCutoff,
        now: now,
      ),
      CueCard(
        icon: '🌤️',
        label: 'Afternoon sunlight',
        timeRange: _formatTimeRange(s.afternoonSunlightStart, s.afternoonSunlightEnd),
        status: _cueStatus(s.afternoonSunlightStart, s.afternoonSunlightEnd),
        scienceExplanation:
            'Late-afternoon light recalibrates your circadian phase and '
            'builds a "second anchor" for your clock. It also buffers '
            'against the phase-advancing effect of artificial light in '
            'the evening, making you less sensitive to screens after dark.',
        cueTime: s.afternoonSunlightStart,
        now: now,
      ),
      CueCard(
        icon: '🌙',
        label: 'Dim the lights',
        timeRange: _fmt(s.dimLights),
        status: _cueStatus(
          s.dimLights.subtract(halfHour),
          s.dimLights.add(halfHour),
        ),
        scienceExplanation:
            'Bright light in the 2 hours before bed suppresses melatonin '
            'by up to 50%. Dimming overhead lights and switching to warm, '
            'low sources signals your brain that night is approaching and '
            'accelerates the melatonin rise needed for deep sleep.',
        cueTime: s.dimLights,
        now: now,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) _animated(i, cards[i]),
      ],
    );
  }
}
