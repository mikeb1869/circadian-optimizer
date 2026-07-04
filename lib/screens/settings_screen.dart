import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/circadian_schedule.dart';
import '../repositories/sun_times_repository.dart';
import '../services/notification_service.dart';
import '../viewmodels/schedule_viewmodel.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _viewModel = GetIt.instance<ScheduleViewModel>();
  final _notificationService = GetIt.instance<NotificationService>();
  final _sunTimesRepository = GetIt.instance<SunTimesRepository>();

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);

    if (!value) {
      await _notificationService.cancelAll();
    } else {
      final state = _viewModel.state.value;
      final location = _viewModel.lastLocation;
      if (state is ScheduleSuccess && location != null) {
        final tomorrowSunTimes = await _sunTimesRepository.getSunTimes(
          location,
          date: DateTime.now().add(const Duration(days: 1)),
        );
        final tomorrowSchedule = CircadianSchedule.fromSunTimes(tomorrowSunTimes);
        await _notificationService.scheduleAllCueNotifications(
          state.schedule,
          tomorrowSchedule,
        );
      }
    }
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'mjbarrera@clicksavvydigital.com',
      queryParameters: {'subject': 'Helio App Feedback'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_complete');

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF0F1F5C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F1F5C),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const _SectionHeader(title: 'Notifications'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text('Daily cue reminders'),
              subtitle: const Text('Morning light, caffeine cutoff, and more'),
              value: _notificationsEnabled,
              onChanged: _setNotificationsEnabled,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Schedule'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('Refresh schedule'),
              subtitle: const Text('Recalculate using your current location'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _viewModel.loadSchedule();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing your schedule...'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('Replay onboarding'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _resetOnboarding,
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Feedback'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: const Text('Send feedback'),
              subtitle: const Text('Share your thoughts with the developer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _sendFeedback,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Colors.white54,
        ),
      ),
    );
  }
}
