import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profile_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      emoji: '⏱️',
      title: 'Know the real\ncost of everything.',
      subtitle:
          'Every price tag hides the true cost — the hours of your life you traded for it.',
      accent: Color(0xFF4A90D9),
    ),
    _OnboardPage(
      emoji: '📦',
      title: 'Scan. Calculate.\nThink twice.',
      subtitle:
          'Point your camera at any barcode. LifeHours converts the price into working hours — instantly.',
      accent: Color(0xFF4CAF93),
    ),
    _OnboardPage(
      emoji: '📊',
      title: 'Track your\nmonthly budget.',
      subtitle:
          'See where your time goes. Get AI-powered insights at the end of every month.',
      accent: Color(0xFF9B59B6),
    ),
    _OnboardPage(
      emoji: '💰',
      title: "One last thing —\nyour hourly rate.",
      subtitle:
          'Enter your wage so LifeHours can calculate exactly how many hours each purchase costs you.',
      accent: Color(0xFFF5A623),
      isLast: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Column(
          children: [
            // Skip butonu
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                child: _currentPage < _pages.length - 1
                    ? GestureDetector(
                        onTap: _finishOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      )
                    : const SizedBox(height: 20),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) {
                  _fadeController.reset();
                  setState(() => _currentPage = i);
                  _fadeController.forward();
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    page: _pages[index],
                    fadeAnim: _fadeAnim,
                  );
                },
              ),
            ),

            // Dots + buton
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  // Dot indikatör
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? page.accent : Colors.white12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Ana buton
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: page.accent,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: page.accent.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: page.isLast ? _finishOnboarding : _nextPage,
                        child: Center(
                          child: Text(
                            page.isLast ? "Let's set up my wage →" : 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
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

// ── Tek sayfa widget ────────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardPage page;
  final Animation<double> fadeAnim;

  const _OnboardingPage({required this.page, required this.fadeAnim});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Büyük emoji / ikon alanı
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: page.accent.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(page.emoji, style: const TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 40),

            // Başlık
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Alt yazı
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ──────────────────────────────────────────────────────────────
class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final bool isLast;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.isLast = false,
  });
}
