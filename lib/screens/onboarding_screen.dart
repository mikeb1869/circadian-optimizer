import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

const _bg = Color(0xFF0F1F5C);
const _amber = Color(0xFFFDB813);

class _PageData {
  final String assetPath;
  final String title;
  final String body;
  final String buttonLabel;
  const _PageData({
    required this.assetPath,
    required this.title,
    required this.body,
    required this.buttonLabel,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _PageData(
      assetPath: 'assets/illustrations/onboarding_1.svg',
      title: 'Your body runs on sunlight',
      body:
          'Your circadian rhythm controls energy, mood, and sleep. '
          'Light is the master switch.',
      buttonLabel: 'Next',
    ),
    _PageData(
      assetPath: 'assets/illustrations/onboarding_2.svg',
      title: 'Three anchors, one schedule',
      body:
          'Morning light sets your clock. Afternoon light locks it. '
          'Evening darkness lets melatonin rise.',
      buttonLabel: 'Next',
    ),
    _PageData(
      assetPath: 'assets/illustrations/onboarding_3.svg',
      title: 'Built for wherever you are',
      body:
          'Sunrise in Medellín isn\'t sunrise in Tokyo. Your schedule '
          'updates automatically wherever you are.',
      buttonLabel: 'Next',
    ),
    _PageData(
      assetPath: 'assets/illustrations/onboarding_4.svg',
      title: 'Your location stays yours',
      body:
          'We use GPS only to calculate sunrise and sunset. Your location '
          'is never stored, shared, or tracked.',
      buttonLabel: 'Allow location',
    ),
    _PageData(
      assetPath: 'assets/illustrations/onboarding_5.svg',
      title: 'Four nudges a day, that\'s it',
      body:
          'One notification per cue. No noise, no tracking. '
          'Turn them off any time in Settings.',
      buttonLabel: 'Get Started',
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    await GetIt.instance<NotificationService>().requestPermission();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: _currentPage > 0
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: _onBack,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _OnboardingPage(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? _amber
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _amber,
                        foregroundColor: _bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        page.buttonLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _PageData page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(page.assetPath, height: 220),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
