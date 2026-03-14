import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool isMonthly = true;
  int dailyHours = 8;
  String selectedCurrency = '\$';
  final TextEditingController _salaryController = TextEditingController();
  final List<String> currencies = ['\$', '€', '£', '₺'];
  bool _isFirstSetup = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    final salary = prefs.getDouble('salary_amount') ?? 0;
    final monthly = prefs.getBool('is_monthly') ?? true;
    final hours = prefs.getInt('daily_hours') ?? 8;
    final currency = prefs.getString('currency') ?? '\$';
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    setState(() {
      isMonthly = monthly;
      dailyHours = hours;
      selectedCurrency = currency;
      if (salary > 0) _salaryController.text = salary.toStringAsFixed(0);
      // Onboarding'den geliyorsak ilk kurulum
      _isFirstSetup = !onboardingDone || salary == 0;
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  double get hourlyRate {
    final amount = double.tryParse(_salaryController.text) ?? 0;
    if (isMonthly) {
      return amount / (22 * dailyHours);
    }
    return amount;
  }

  Future<void> _saveAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    final oldRate = prefs.getDouble('hourly_rate') ?? 0;
    final newRate = hourlyRate;

    final historyJson = prefs.getStringList('scan_history') ?? [];
    final hasHistory = historyJson.isNotEmpty;
    final rateChanged = oldRate > 0 && (oldRate - newRate).abs() > 0.001;

    await prefs.setDouble('hourly_rate', newRate);
    await prefs.setString('currency', selectedCurrency);
    await prefs.setInt('daily_hours', dailyHours);
    await prefs.setBool('is_monthly', isMonthly);
    await prefs.setDouble(
      'salary_amount',
      double.tryParse(_salaryController.text) ?? 0,
    );
    // Onboarding tamamlandı olarak işaretle
    await prefs.setBool('onboarding_done', true);

    if (hasHistory && rateChanged && mounted) {
      final recalc = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: const Color(0xFF1A2E45),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('🔄', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 12),
              const Text(
                'Recalculate existing entries?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your wage has changed. Do you want to update the work-hour values of your existing history entries with the new rate?',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Old rate',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$selectedCurrency${oldRate.toStringAsFixed(2)}/hr',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white24,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'New rate',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$selectedCurrency${newRate.toStringAsFixed(2)}/hr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(ctx, true),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Center(
                      child: Text(
                        'YES, RECALCULATE',
                        style: TextStyle(
                          color: Color(0xFF0D1B2A),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.pop(ctx, false),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Center(
                      child: Text(
                        'KEEP ORIGINAL VALUES',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (recalc == true) {
        await _recalculateHistory(oldRate, newRate, prefs);
      }
    }

    if (!mounted) return;

    // İlk kurulumsa HomeScreen'e git, değilse sadece geri dön
    if (_isFirstSetup) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _recalculateHistory(
    double oldRate,
    double newRate,
    SharedPreferences prefs,
  ) async {
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final updated = historyJson.map((itemStr) {
      final map = Map<String, dynamic>.from(jsonDecode(itemStr) as Map);
      final priceStr = map['price'] as String? ?? '';
      final price =
          double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
      if (price > 0 && newRate > 0) {
        final hoursNeeded = price / newRate;
        final h = hoursNeeded.floor();
        final m = ((hoursNeeded - h) * 60).round();
        map['time'] = '${h}h ${m}m';
      }
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList('scan_history', updated);

    final manualHours = prefs.getDouble('manual_spent_hours') ?? 0;
    if (manualHours > 0 && oldRate > 0) {
      final originalAmount = manualHours * oldRate;
      final newManualHours = originalAmount / newRate;
      await prefs.setDouble('manual_spent_hours', newManualHours);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isFirstSetup
            ? null // İlk kurulumda geri butonu yok
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Profile Setup',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Let's calculate\nyour worth.",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your data stays safely on your device only.',
                style: TextStyle(fontSize: 14, color: Colors.white38),
              ),
              const SizedBox(height: 36),

              // Income Type
              const Text(
                'INCOME TYPE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E45),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _toggleButton(
                      'Monthly Net',
                      isMonthly,
                      () => setState(() => isMonthly = true),
                    ),
                    _toggleButton(
                      'Hourly Net',
                      !isMonthly,
                      () => setState(() => isMonthly = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Currency
              const Text(
                'CURRENCY',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: currencies
                    .map(
                      (c) => GestureDetector(
                        onTap: () => setState(() => selectedCurrency = c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selectedCurrency == c
                                ? Colors.white
                                : const Color(0xFF1A2E45),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: selectedCurrency == c
                                  ? const Color(0xFF0D1B2A)
                                  : Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),

              // Amount
              Text(
                isMonthly ? 'MONTHLY NET SALARY' : 'HOURLY NET WAGE',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCurrency,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 1, height: 36, color: Colors.white12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _salaryController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: isMonthly ? '3,000' : '25',
                          hintStyle: const TextStyle(
                            color: Colors.white24,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Daily Hours
              const Text(
                'WORKING HOURS PER DAY',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Text('⏱', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Text(
                      '$dailyHours hours / day',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (dailyHours > 1) setState(() => dailyHours--);
                      },
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (dailyHours < 16) setState(() => dailyHours++);
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              // Hourly Rate Preview
              if (_salaryController.text.isNotEmpty) ...[
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2E45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR HOURLY RATE',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$selectedCurrency${hourlyRate.toStringAsFixed(2)} / hr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Save Button
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _saveAndContinue,
                  child: const SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Center(
                      child: Text(
                        'SAVE & GET STARTED',
                        style: TextStyle(
                          color: Color(0xFF0D1B2A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggleButton(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF0D1B2A) : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
