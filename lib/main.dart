import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/history_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const LifeHoursApp());
}

class LifeHoursApp extends StatelessWidget {
  const LifeHoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeHours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D1B2A)),
        useMaterial3: true,
      ),
      home: const _AppEntry(),
    );
  }
}

// İlk açılışta onboarding mı, ana ekran mı?
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    if (!done) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kısa splash — kontrol yapılırken
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_rounded, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'LifeHours',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Map<String, dynamic>> kCategories = [
  {'id': 'living', 'label': 'Living', 'icon': '🛒', 'color': Color(0xFF4A90D9)},
  {'id': 'fun', 'label': 'Fun', 'icon': '🎉', 'color': Color(0xFF9B59B6)},
  {
    'id': 'shopping',
    'label': 'Shopping',
    'icon': '👕',
    'color': Color(0xFFF5A623),
  },
  {
    'id': 'education',
    'label': 'Education',
    'icon': '📚',
    'color': Color(0xFF4CAF93),
  },
  {'id': 'health', 'label': 'Health', 'icon': '💪', 'color': Color(0xFFE57373)},
];

// Recurring öneri yapılacak kategoriler
const List<String> kRecurringCategories = ['living', 'health', 'education'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? _hourlyRate;
  String _currency = '\$';
  bool _profileSet = false;
  bool _rateVisible = true;
  List<Map<String, String>> _recentScans = [];
  double _totalMonthlyHours = 0;
  double _spentHours = 0;
  int _dailyHours = 8;
  bool _hasRecurringSuggestions = false;

  // ── Manuel entry kartı ────────────────────────────────────────────────────
  bool _showManualCard = false;
  String _manualCardMessage = '';
  String _manualCardEmoji = '';
  static final _random = Random();

  static const Map<String, List<Map<String, String>>> _manualMessages = {
    'living': [
      {
        'e': '🏠',
        'm':
            'Bills are the invisible backbone of daily life — tracking them puts you in control.',
      },
      {
        'e': '💡',
        'm':
            'Fixed costs tracked. Knowing your baseline is the foundation of every smart budget.',
      },
      {
        'e': '💰',
        'm':
            'This payment keeps your life running. Now you know exactly what that costs.',
      },
      {
        'e': '📊',
        'm':
            'Every living expense logged is a leak in your budget stopped before it drains you.',
      },
      {
        'e': '🏠',
        'm':
            'Tracking your living costs is step one to spending less on them over time.',
      },
    ],
    'fun': [
      {
        'e': '🎉',
        'm':
            'Will you remember this moment forever? If yes — worth every minute of work.',
      },
      {
        'e': '😊',
        'm':
            'We work to enjoy life. Sometimes you have to taste the fruit. Enjoy it guilt-free.',
      },
      {
        'e': '✨',
        'm':
            'Is this real joy or just filling a void? Either way — now it\'s tracked.',
      },
      {
        'e': '🎯',
        'm':
            'Experiences pay more happiness dividends than things. Good choice.',
      },
      {
        'e': '🌟',
        'm': 'Rest and fun are part of the deal. No guilt. Just awareness.',
      },
    ],
    'shopping': [
      {
        'e': '👕',
        'm': 'Can you combine this with at least 3 things you already own?',
      },
      {
        'e': '🛍',
        'm':
            'Will this still excite you this time next year? If yes — it\'s worth it.',
      },
      {
        'e': '💳',
        'm':
            'It\'s not the discount that makes you rich — it\'s the usage rate.',
      },
      {
        'e': '👗',
        'm':
            'Your wardrobe should be a living space, not a museum. Does this earn its place?',
      },
      {
        'e': '✂️',
        'm':
            'One season or a lifetime? That\'s what the quality will tell you.',
      },
    ],
    'education': [
      {
        'e': '📚',
        'm':
            'This knowledge will pay you back with interest. You\'re not spending — you\'re investing.',
      },
      {
        'e': '🎓',
        'm':
            'Have you made space in your calendar to actually use what you just bought?',
      },
      {
        'e': '🚀',
        'm':
            'Are you collecting certificates or building skills? Keep making it the latter.',
      },
      {
        'e': '💡',
        'm':
            'Investing in yourself is the highest ROI transaction you can make.',
      },
      {
        'e': '🧠',
        'm':
            'Deepening one expertise beats having ten half-knowledges. Keep going.',
      },
    ],
    'health': [
      {
        'e': '💪',
        'm':
            'Every cent spent on your health is a quality hour added to your life.',
      },
      {
        'e': '❤️',
        'm':
            'Your body is your only real home. Taking care of it is your most basic responsibility.',
      },
      {
        'e': '🏃',
        'm':
            'Staying healthy is the greatest luxury. You just made a smart call.',
      },
      {
        'e': '🌱',
        'm':
            'Taking care of yourself now costs far less than not doing so later.',
      },
      {
        'e': '🧘',
        'm':
            'The best health investments work on both body and mind. Does this one?',
      },
    ],
  };

  // ── Keyword bazlı özel mesajlar — PDF içeriğiyle zenginleştirildi ──────────
  static const List<Map<String, dynamic>> _keywordMessages = [
    // 🏠 Kira / Ev
    {
      'keywords': ['rent', 'kira'],
      'e': '🏠',
      'messages': [
        'One day these payments will be memories, not obligations. Your own place is closer than it feels.',
        'Every rent payment is a disciplined step toward your future home. You\'re building patiently.',
        'Paying rent is temporary. The habits you\'re building right now are permanent.',
        'Housing is the most basic form of self-care. These hours are buying you peace and rest.',
        'This is not just rent — it\'s the foundation you\'re standing on while you build something bigger.',
      ],
    },
    // 🛒 Market / Grocery
    {
      'keywords': [
        'grocery',
        'groceries',
        'supermarket',
        'market',
        'food shop',
        'lidl',
        'aldi',
        'tesco',
        'dunnes',
      ],
      'e': '🛒',
      'messages': [
        'Everything in your cart becomes your energy. You just invested in quality fuel.',
        'Stocking up only saves money if it doesn\'t end up in the bin. Track it. Use it.',
        'Are you buying because you\'re hungry, or because your mind is tired? Awareness is the best diet.',
        'The best grocery run is one where nothing goes to waste. You\'re staying ahead of it.',
        'Is what\'s in your cart worth the hours you worked for it? A good question to keep asking.',
      ],
    },
    // 🏋️ Spor Salonu / Gym
    {
      'keywords': [
        'gym',
        'fitness',
        'sport',
        'membership',
        'spor',
        'pilates',
        'yoga',
        'crossfit',
      ],
      'e': '🏋️',
      'messages': [
        'Equipment doesn\'t make athletes — sweat does. Now go earn this payment back.',
        'Does this membership actually get you out the door? That\'s the only metric that matters.',
        'Your body is your only real home. Every session is maintenance on the most important thing you own.',
        'If you\'re ready to sweat, this trade is worth every minute.',
        'The gym is expensive. So is not going. You made the right call.',
      ],
    },
    // ⚡ Faturalar
    {
      'keywords': [
        'electricity',
        'electric',
        'gas',
        'water',
        'utility',
        'utilities',
        'bill',
        'fatura',
        'broadband',
      ],
      'e': '⚡',
      'messages': [
        'Bills are the invisible infrastructure of modern life. Now you can see exactly what yours costs.',
        'Tracking fixed costs is the first step to stopping the silent leaks in your budget.',
        'This payment is an exchange — your work hours become light, heat and connection. Fair trade.',
        'You\'re in control of your expenses. That\'s rarer than it sounds.',
        'Knowing your fixed costs means no surprises. That\'s financial peace of mind.',
      ],
    },
    // 📚 Kurs / Kitap
    {
      'keywords': [
        'course',
        'class',
        'book',
        'books',
        'training',
        'workshop',
        'seminar',
        'kurs',
        'kitap',
        'udemy',
        'coursera',
      ],
      'e': '📚',
      'messages': [
        'This knowledge will pay you back with interest. You\'re not spending — you\'re compounding.',
        'Have you blocked time in your calendar to actually use what you just bought?',
        'Investing in yourself is the highest ROI transaction you\'ll ever make.',
        'Are you collecting certificates or building real skills? Make sure it\'s the latter.',
        'The cost of learning once is always less than the cost of not knowing.',
      ],
    },
    // 🍽️ Restoran / Kahve
    {
      'keywords': [
        'restaurant',
        'cafe',
        'coffee',
        'lunch',
        'dinner',
        'takeaway',
        'takeout',
        'yemek',
        'starbucks',
        'costa',
      ],
      'e': '🍽️',
      'messages': [
        'Coffee is just the excuse — the real value is the conversation around it.',
        'Sometimes you need to taste the fruit. Let this meal be a well-earned reward.',
        'If this meal takes your stress away, every minute you worked for it was worth it.',
        'No judgment — just clarity. Now you know what eating out really costs.',
        'We work so we can live. Sometimes living means a good meal. Logged.',
      ],
    },
    // 📱 Abonelikler
    {
      'keywords': [
        'netflix',
        'spotify',
        'subscription',
        'prime',
        'disney',
        'apple',
        'youtube',
        'hbo',
        'dazn',
      ],
      'e': '📱',
      'messages': [
        'Are you sure you\'re not trading hours of your life for shows you don\'t actually watch?',
        'Small monthly fees add up quietly. Is this subscription still earning its place?',
        'Is the digital world drowning you or lifting you? Worth asking.',
        'Subscriptions are the sneakiest budget leaks. You just caught this one.',
        'Every subscription should justify itself monthly. Does this one?',
      ],
    },
    // ✈️ Seyahat
    {
      'keywords': [
        'flight',
        'hotel',
        'holiday',
        'vacation',
        'travel',
        'airbnb',
        'seyahat',
        'ryanair',
        'booking',
      ],
      'e': '✈️',
      'messages': [
        'Experiences pay more happiness dividends than things ever will.',
        'When this trip ends, what will be left in your heart — not your wallet?',
        'Journeys feed the soul. The hours you spent earning this are turning into new horizons.',
        'The memories from this trip will outlast any expense. Worth every minute.',
        'Life is short and the world is wide. These hours are well spent.',
      ],
    },
    // 💊 Sağlık / Eczane
    {
      'keywords': [
        'pharmacy',
        'medicine',
        'doctor',
        'dental',
        'hospital',
        'eczane',
        'chemist',
        'physio',
      ],
      'e': '💊',
      'messages': [
        'Every cent spent on health is a quality hour added to your life. Great investment.',
        'Taking care of yourself now costs far less than not doing so later.',
        'Your health is not optional. This is your most important expense — and you\'re on top of it.',
        'Caring for yourself is not a cost — it\'s your most basic responsibility.',
        'Good health is the foundation everything else is built on. You\'re protecting it.',
      ],
    },
    // 🎮 Eğlence / Oyun
    {
      'keywords': [
        'game',
        'gaming',
        'cinema',
        'movie',
        'concert',
        'ticket',
        'oyun',
        'playstation',
        'steam',
      ],
      'e': '🎮',
      'messages': [
        'Will you remember this moment forever? If yes — you\'re exactly where you should be.',
        'Is this genuine joy or just escaping? Either way — rest is part of a balanced life.',
        'We work hard so we can enjoy life. This is the point. No guilt.',
        'Is this excitement temporary or a real spark? Worth noticing the difference.',
        'Rest and play are not optional extras. They\'re part of the whole deal.',
      ],
    },
    // 🚌 Ulaşım
    {
      'keywords': [
        'transport',
        'bus',
        'train',
        'taxi',
        'uber',
        'fuel',
        'petrol',
        'diesel',
        'commute',
        'metro',
        'tram',
        'luas',
        'dart',
      ],
      'e': '🚌',
      'messages': [
        'Every commute gets you somewhere — literally and figuratively.',
        'The cost of showing up is real. Now you know exactly what it is.',
        'Knowing your transport costs helps you spot smarter alternatives over time.',
        'Getting there is half the battle. You\'re tracking the real cost of it.',
        'These hours paid for movement. Movement creates opportunity.',
      ],
    },
    // 👶 Çocuk / Aile
    {
      'keywords': [
        'childcare',
        'nursery',
        'school',
        'kids',
        'baby',
        'children',
      ],
      'e': '👶',
      'messages': [
        'Investing in your children is the longest-term investment there is.',
        'Every expense here is love expressed in financial form.',
        'The cost of raising a family is real. So is the return.',
        'You\'re building someone\'s future. These hours are well spent.',
        'No investment compounds longer than the one you make in your children.',
      ],
    },
  ];

  // Keyword matching — ismi kontrol et, varsa özel mesaj döndür
  Map<String, String>? _matchKeyword(String name) {
    final lower = name.toLowerCase().trim();
    for (final entry in _keywordMessages) {
      final keywords = entry['keywords'] as List;
      for (final kw in keywords) {
        if (lower.contains(kw as String)) {
          final msgs = (entry['messages'] as List).cast<String>();
          final msg = msgs[_random.nextInt(msgs.length)];
          return {'e': entry['e'] as String, 'm': msg};
        }
      }
    }
    return null;
  }

  void _triggerManualCard(String category, double hours, String name) {
    // Önce keyword'e bak, yoksa kategoriye dön
    final keywordMatch = _matchKeyword(name);
    final Map<String, String> pick;
    if (keywordMatch != null) {
      pick = keywordMatch;
    } else {
      final msgs = _manualMessages[category] ?? _manualMessages['living']!;
      final catPick = msgs[_random.nextInt(msgs.length)];
      pick = {'e': catPick['e']!, 'm': catPick['m']!};
    }
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    setState(() {
      _manualCardEmoji = pick['e']!;
      _manualCardMessage =
          '${pick['m']}\n\nThat\'s $timeStr of your work time.';
      _showManualCard = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData().then((_) => _checkNewMonth());
  }

  // ── Yeni ay kontrolü ──────────────────────────────────────────────────────
  Future<void> _checkNewMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastOpenedStr = prefs.getString('last_opened_month');
    final currentMonthStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (lastOpenedStr == null) {
      // İlk kullanım — sadece kaydet
      await prefs.setString('last_opened_month', currentMonthStr);
      return;
    }

    if (lastOpenedStr != currentMonthStr) {
      // Yeni ay! Geçen ayın recurring önerilerini göster
      await prefs.setString('last_opened_month', currentMonthStr);
      if (mounted) {
        // Kısa gecikme — ekran yüklenssin
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _showRecurringSheet(isAutoTriggered: true);
      }
    }
  }

  // ── Recurring sheet ───────────────────────────────────────────────────────
  Future<void> _showRecurringSheet({bool isAutoTriggered = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final historyJson = prefs.getStringList('scan_history') ?? [];

    // Geçen ayın harcamalarını bul (recurring kategorilerden)
    final lastMonth = DateTime(now.year, now.month - 1);
    final candidates = <Map<String, String>>[];
    final seenNames = <String>{};

    for (final itemStr in historyJson) {
      final map = Map<String, String>.from(jsonDecode(itemStr) as Map);
      final cat = map['category'] ?? '';
      if (!kRecurringCategories.contains(cat)) continue;

      final tsStr = map['timestamp'] ?? '';
      if (tsStr.isEmpty) continue;
      try {
        final dt = DateTime.parse(tsStr);
        if (dt.month == lastMonth.month && dt.year == lastMonth.year) {
          final name = map['name'] ?? '';
          if (!seenNames.contains(name.toLowerCase())) {
            seenNames.add(name.toLowerCase());
            candidates.add(map);
          }
        }
      } catch (_) {}
    }

    // Bu ayda zaten eklenmiş olanları çıkar
    final thisMonthNames = <String>{};
    for (final itemStr in historyJson) {
      final map = Map<String, String>.from(jsonDecode(itemStr) as Map);
      final tsStr = map['timestamp'] ?? '';
      try {
        final dt = DateTime.parse(tsStr);
        if (dt.month == now.month && dt.year == now.year) {
          thisMonthNames.add((map['name'] ?? '').toLowerCase());
        }
      } catch (_) {}
    }

    final suggestions = candidates
        .where((c) => !thisMonthNames.contains((c['name'] ?? '').toLowerCase()))
        .toList();

    if (suggestions.isEmpty) {
      if (!isAutoTriggered && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recurring suggestions from last month.'),
            backgroundColor: Color(0xFF1A2E45),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final monthName = _monthName(lastMonth.month);
    final selected = List<bool>.filled(suggestions.length, true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCount = selected.where((s) => s).length;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
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

                  // Başlık
                  Row(
                    children: [
                      const Text('🔄', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAutoTriggered
                                  ? 'Welcome to ${_monthName(DateTime.now().month)}!'
                                  : 'Recurring from $monthName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'These were your stable expenses in $monthName. Add them to this month?',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Öneri listesi
                  ...List.generate(suggestions.length, (i) {
                    final s = suggestions[i];
                    final cat = kCategories.firstWhere(
                      (c) => c['id'] == s['category'],
                      orElse: () => kCategories[0],
                    );
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selected[i] = !selected[i]),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: selected[i]
                              ? (cat['color'] as Color).withValues(alpha: 0.12)
                              : const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected[i]
                                ? (cat['color'] as Color).withValues(alpha: 0.5)
                                : Colors.white12,
                            width: selected[i] ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: selected[i]
                                    ? cat['color'] as Color
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selected[i]
                                      ? cat['color'] as Color
                                      : Colors.white38,
                                  width: 1.5,
                                ),
                              ),
                              child: selected[i]
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // İkon + kategori
                            Text(
                              cat['icon'] as String,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            // İsim + kategori
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['name'] ?? '',
                                    style: TextStyle(
                                      color: selected[i]
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    cat['label'] as String,
                                    style: TextStyle(
                                      color: cat['color'] as Color,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Fiyat + süre
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  s['price'] ?? '',
                                  style: TextStyle(
                                    color: selected[i]
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  s['time'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Seç/Kaldır tümü
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setModalState(
                          () => selected.fillRange(0, selected.length, true),
                        ),
                        child: const Text(
                          'Select all',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => setModalState(
                          () => selected.fillRange(0, selected.length, false),
                        ),
                        child: const Text(
                          'Clear all',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ekle butonu
                  Material(
                    color: selectedCount > 0 ? Colors.white : Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: selectedCount > 0
                          ? () async {
                              await _addRecurringItems(suggestions, selected);
                              if (mounted) Navigator.pop(context);
                              _loadData();
                            }
                          : null,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Center(
                          child: Text(
                            selectedCount > 0
                                ? 'ADD $selectedCount ITEM${selectedCount > 1 ? 'S' : ''} TO ${_monthName(DateTime.now().month).toUpperCase()}'
                                : 'SELECT ITEMS TO ADD',
                            style: TextStyle(
                              color: selectedCount > 0
                                  ? const Color(0xFF0D1B2A)
                                  : Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Atla
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addRecurringItems(
    List<Map<String, String>> suggestions,
    List<bool> selected,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final hourlyRate = prefs.getDouble('hourly_rate') ?? 0;

    for (int i = 0; i < suggestions.length; i++) {
      if (!selected[i]) continue;
      final s = suggestions[i];

      // Fiyattan saati yeniden hesapla (rate değişmiş olabilir)
      final priceStr = s['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '0';
      final price = double.tryParse(priceStr) ?? 0;
      String timeStr = s['time'] ?? '0h 0m';
      if (hourlyRate > 0 && price > 0) {
        final hrs = price / hourlyRate;
        final h = hrs.floor();
        final m = ((hrs - h) * 60).round();
        timeStr = '${h}h ${m}m';
      }

      final item = {
        'name': s['name'] ?? '',
        'price': s['price'] ?? '',
        'time': timeStr,
        'category': s['category'] ?? 'living',
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'barcode',
      };
      historyJson.insert(0, jsonEncode(item));
    }

    if (historyJson.length > 50) {
      historyJson.removeRange(50, historyJson.length);
    }
    await prefs.setStringList('scan_history', historyJson);
  }

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }

  // ── Veri yükleme ──────────────────────────────────────────────────────────
  double _parseHours(String timeStr) {
    final hMatch = RegExp(r'(\d+)h').firstMatch(timeStr);
    final mMatch = RegExp(r'(\d+)m').firstMatch(timeStr);
    final h = double.tryParse(hMatch?.group(1) ?? '0') ?? 0;
    final m = double.tryParse(mMatch?.group(1) ?? '0') ?? 0;
    return h + (m / 60);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble('hourly_rate') ?? 0;
    final dailyHours = prefs.getInt('daily_hours') ?? 8;
    final totalHours = 22.0 * dailyHours;
    final now = DateTime.now();

    final historyJson = prefs.getStringList('scan_history') ?? [];
    double spentHours = 0;

    // Sadece bu ayın harcamaları
    for (final item in historyJson) {
      final map = jsonDecode(item) as Map;
      try {
        final dt = DateTime.parse(map['timestamp'] as String? ?? '');
        if (dt.month == now.month && dt.year == now.year) {
          spentHours += _parseHours(map['time'] as String? ?? '');
        }
      } catch (_) {
        spentHours += _parseHours(map['time'] as String? ?? '');
      }
    }

    // Son 3 scan (bu ay)
    final thisMonthScans = historyJson
        .where((item) {
          try {
            final map = jsonDecode(item) as Map;
            final dt = DateTime.parse(map['timestamp'] as String? ?? '');
            return dt.month == now.month && dt.year == now.year;
          } catch (_) {
            return true;
          }
        })
        .take(3)
        .map((e) => Map<String, String>.from(jsonDecode(e) as Map))
        .toList();

    // Recurring öneri var mı kontrol et
    final lastMonth = DateTime(now.year, now.month - 1);
    final thisMonthNames = <String>{};
    for (final item in historyJson) {
      final map = jsonDecode(item) as Map;
      try {
        final dt = DateTime.parse(map['timestamp'] as String? ?? '');
        if (dt.month == now.month && dt.year == now.year) {
          thisMonthNames.add((map['name'] as String? ?? '').toLowerCase());
        }
      } catch (_) {}
    }
    final seenLastMonth = <String>{};
    bool hasRecurring = false;
    for (final item in historyJson) {
      final map = jsonDecode(item) as Map;
      final cat = map['category'] as String? ?? '';
      if (!kRecurringCategories.contains(cat)) continue;
      try {
        final dt = DateTime.parse(map['timestamp'] as String? ?? '');
        if (dt.month == lastMonth.month && dt.year == lastMonth.year) {
          final name = (map['name'] as String? ?? '').toLowerCase();
          if (!seenLastMonth.contains(name) && !thisMonthNames.contains(name)) {
            seenLastMonth.add(name);
            hasRecurring = true;
            break;
          }
        }
      } catch (_) {}
    }

    setState(() {
      _hourlyRate = rate > 0 ? rate : null;
      _currency = prefs.getString('currency') ?? '\$';
      _profileSet = rate > 0;
      _recentScans = thisMonthScans;
      _totalMonthlyHours = totalHours;
      _spentHours = spentHours;
      _dailyHours = dailyHours;
      _hasRecurringSuggestions = hasRecurring;
    });

    // Bildirimler
    _checkBudgetNotification(spentHours, totalHours);
    NotificationService().scheduleMonthlyReport();
  }

  Future<void> _checkBudgetNotification(double spent, double total) async {
    if (total <= 0) return;
    final pct = spent / total;
    final prefs = await SharedPreferences.getInstance();
    final warned = prefs.getBool('budget_80_warned') ?? false;
    final warningMonth = prefs.getString('budget_warning_month') ?? '';
    final thisMonth = '${DateTime.now().year}-${DateTime.now().month}';

    // Ay değiştiyse eski uyarıyı sıfırla
    if (warningMonth != thisMonth) {
      await prefs.setBool('budget_80_warned', false);
      await prefs.setString('budget_warning_month', thisMonth);
    }

    // %80 geçtiyse ve bu ay henüz uyarmadıysak bildirim gönder
    if (pct >= 0.8 && !warned) {
      await prefs.setBool('budget_80_warned', true);
      // Harcanan para toplamını hesapla
      final historyJson = prefs.getStringList('scan_history') ?? [];
      final now = DateTime.now();
      double totalMoney = 0;
      for (final item in historyJson) {
        try {
          final map = jsonDecode(item) as Map;
          final dt = DateTime.parse(map['timestamp'] as String);
          if (dt.month == now.month && dt.year == now.year) {
            final priceStr = (map['price'] as String? ?? '').replaceAll(
              RegExp(r'[^\d.]'),
              '',
            );
            totalMoney += double.tryParse(priceStr) ?? 0;
          }
        } catch (_) {}
      }
      await NotificationService().showBudgetWarning(
        spentPct: pct,
        spentTime: _formatHours(spent),
        budgetTime: _formatHours(total),
        currency: _currency,
        spentMoney: totalMoney,
      );
    }

    // %80'in altına düştüyse flag'i sıfırla — tekrar çıkınca bildirim gelsin
    if (pct < 0.8 && warned) {
      await prefs.setBool('budget_80_warned', false);
    }
  }

  Future<void> _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
    );
    _loadData();
  }

  Future<void> _showSettingsSheet() async {
    final prefs = await SharedPreferences.getInstance();
    bool dailyEnabled = prefs.getBool('daily_reminder_enabled') ?? false;
    int reminderHour = prefs.getInt('reminder_hour') ?? 20;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Profil
              _settingsTile(
                icon: Icons.person_outline,
                title: 'Edit Wage & Profile',
                subtitle: _hourlyRate != null
                    ? '$_currency${_hourlyRate!.toStringAsFixed(2)}/hr'
                    : 'Not set',
                onTap: () {
                  Navigator.pop(ctx);
                  _goToProfile();
                },
              ),
              const SizedBox(height: 12),
              _settingsTile(
                icon: Icons.key_outlined,
                title: 'Anthropic API Key',
                subtitle: 'Required for AI Report',
                onTap: () async {
                  final prefs2 = await SharedPreferences.getInstance();
                  final currentKey =
                      prefs2.getString('anthropic_api_key') ?? '';
                  final controller = TextEditingController(text: currentKey);
                  if (!mounted) return;
                  await showDialog(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      backgroundColor: const Color(0xFF1A2E45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'API Key',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'sk-ant-api03-...',
                          hintStyle: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await prefs2.setString(
                              'anthropic_api_key',
                              controller.text.trim(),
                            );
                            if (mounted) Navigator.pop(ctx2);
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Günlük hatırlatıcı toggle
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Reminder',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Every day at ${reminderHour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: dailyEnabled,
                    activeColor: const Color(0xFF4CAF93),
                    onChanged: (val) async {
                      setSheet(() => dailyEnabled = val);
                      await prefs.setBool('daily_reminder_enabled', val);
                      if (val) {
                        await NotificationService().scheduleDailyReminder(
                          hour: reminderHour,
                        );
                      } else {
                        await NotificationService().cancelDailyReminder();
                      }
                    },
                  ),
                ],
              ),

              // Saat seçici (sadece enabled ise)
              if (dailyEnabled) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 54),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reminder time:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: List.generate(4, (i) {
                          final h = [8, 12, 18, 20][i];
                          final label = ['8:00', '12:00', '18:00', '20:00'][i];
                          final isSelected = reminderHour == h;
                          return GestureDetector(
                            onTap: () async {
                              setSheet(() => reminderHour = h);
                              await prefs.setInt('reminder_hour', h);
                              await NotificationService().scheduleDailyReminder(
                                hour: h,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF4CAF93,
                                      ).withValues(alpha: 0.2)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4CAF93)
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF4CAF93)
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),

              // Budget uyarısı bilgi satırı
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Warning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Notified when budget hits 80%',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF4CAF93),
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ],
      ),
    );
  }

  Future<void> _goToScanner() async {
    if (mounted) setState(() => _showManualCard = false);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    _loadData();
  }

  Future<void> _goToHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
    _loadData();
  }

  Future<void> _showMonthlyReport() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MonthlyReportSheet(
        currency: _currency,
        hourlyRate: _hourlyRate ?? 0,
        dailyHours: _dailyHours,
        totalMonthlyHours: _totalMonthlyHours,
      ),
    );
  }

  String? _workDaysText(String timeStr) {
    final hours = _parseHours(timeStr);
    if (_dailyHours <= 0 || hours < _dailyHours) return null;
    final days = hours / _dailyHours;
    return '🗓 ${days.toStringAsFixed(1)} work days';
  }

  void _showAddManualDialog() {
    if (mounted) setState(() => _showManualCard = false);
    final amountController = TextEditingController();
    final nameController = TextEditingController();
    String selectedCategory = 'living';
    DateTime selectedDate = DateTime.now();

    String _formatPickedDate(DateTime dt) {
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return 'Today';
      }
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text(
                    'Add Manual Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add expenses not scanned',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'DESCRIPTION (optional)',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Gym membership',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'CATEGORY',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        children: kCategories.take(3).map((cat) {
                          final isSelected = selectedCategory == cat['id'];
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(
                                () => selectedCategory = cat['id'],
                              ),
                              child: _catButton(cat, isSelected),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...kCategories.skip(3).map((cat) {
                            final isSelected = selectedCategory == cat['id'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(
                                  () => selectedCategory = cat['id'],
                                ),
                                child: _catButton(cat, isSelected),
                              ),
                            );
                          }),
                          const Expanded(child: SizedBox()),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _currency,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 32, color: Colors.white12),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Colors.white24,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_hourlyRate != null)
                    ValueListenableBuilder(
                      valueListenable: amountController,
                      builder: (context, value, _) {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0) return const SizedBox.shrink();
                        final hrs = amount / _hourlyRate!;
                        final h = hrs.floor();
                        final m = ((hrs - h) * 60).round();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '= ${h}h ${m}m of your time',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // ── Tarih seçici ──────────────────────────────────────────
                  const Text(
                    'DATE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(DateTime.now().year - 2),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.white,
                                onPrimary: Color(0xFF0D1B2A),
                                surface: Color(0xFF1A2E45),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF0D1B2A),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              selectedDate.month != DateTime.now().month ||
                                  selectedDate.year != DateTime.now().year
                              ? Colors.blueAccent.withValues(alpha: 0.6)
                              : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color:
                                selectedDate.month != DateTime.now().month ||
                                    selectedDate.year != DateTime.now().year
                                ? Colors.blueAccent
                                : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatPickedDate(selectedDate),
                            style: TextStyle(
                              color:
                                  selectedDate.month != DateTime.now().month ||
                                      selectedDate.year != DateTime.now().year
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Geçmiş ay seçildiyse küçük uyarı
                  if (selectedDate.month != DateTime.now().month ||
                      selectedDate.year != DateTime.now().year)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blueAccent,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Will be added to ${_monthLabel(selectedDate)}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount <= 0 || _hourlyRate == null) return;
                        final hrs = amount / _hourlyRate!;
                        final h = hrs.floor();
                        final m = ((hrs - h) * 60).round();
                        final prefs = await SharedPreferences.getInstance();
                        final historyJson =
                            prefs.getStringList('scan_history') ?? [];
                        // Seçilen tarihi kullan, saati bugünden al
                        final timestamp = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          DateTime.now().hour,
                          DateTime.now().minute,
                        ).toIso8601String();
                        final item = {
                          'name': nameController.text.isEmpty
                              ? 'Manual Entry'
                              : nameController.text,
                          'price': '$_currency${amount.toStringAsFixed(2)}',
                          'time': '${h}h ${m}m',
                          'category': selectedCategory,
                          'timestamp': timestamp,
                          'source': 'manual',
                        };
                        historyJson.insert(0, jsonEncode(item));
                        if (historyJson.length > 50) historyJson.removeLast();
                        await prefs.setStringList('scan_history', historyJson);
                        if (mounted) Navigator.pop(context);
                        _loadData();
                        _triggerManualCard(
                          selectedCategory,
                          hrs,
                          nameController.text,
                        );
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Center(
                          child: Text(
                            'ADD TO BUDGET',
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
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _monthLabel(DateTime dt) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    if (dt.month == now.month && dt.year == now.year) return 'This Month';
    if (dt.month == now.month - 1 && dt.year == now.year) return 'Last Month';
    return '${names[dt.month]} ${dt.year}';
  }

  Widget _catButton(Map<String, dynamic> cat, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (cat['color'] as Color).withValues(alpha: 0.25)
            : const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? cat['color'] as Color : Colors.white12,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            cat['label'] as String,
            style: TextStyle(
              color: isSelected ? cat['color'] as Color : Colors.white38,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatHours(double totalHours) {
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    return '${h}h ${m}m';
  }

  Map<String, dynamic>? _getCatById(String? id) {
    try {
      return kCategories.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalMonthlyHours > 0
        ? (_spentHours / _totalMonthlyHours).clamp(0.0, 1.0)
        : 0.0;
    final isOverBudget = _spentHours > _totalMonthlyHours;
    final overHours = _spentHours - _totalMonthlyHours;
    final remainingHours = (_totalMonthlyHours - _spentHours).clamp(
      0.0,
      double.infinity,
    );
    final remainingWorkDays = _dailyHours > 0
        ? (remainingHours / _dailyHours).ceil()
        : 0;
    final rawPercentage = _totalMonthlyHours > 0
        ? (_spentHours / _totalMonthlyHours * 100).round()
        : 0;
    final percentage = rawPercentage;
    final barColor = progress < 0.5
        ? const Color(0xFF4CAF93)
        : progress < 0.8
        ? const Color(0xFFF5A623)
        : const Color(0xFFE57373);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: _profileSet
            ? GestureDetector(
                onTap: _showMonthlyReport,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AI Report',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: _showSettingsSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_showManualCard) setState(() => _showManualCard = false);
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/home_logo.png',
                    width: 260,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    'LifeHours',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Know the real cost of everything.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4CAF93)),
                  ),
                  const SizedBox(height: 20),

                  // Hourly rate bar
                  if (_profileSet && _hourlyRate != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _rateVisible
                                ? '$_currency${_hourlyRate!.toStringAsFixed(2)} / hr'
                                : '$_currency•••• / hr',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _rateVisible = !_rateVisible),
                            child: Icon(
                              _rateVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _goToProfile,
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white38,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _goToProfile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.white54,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Set up your profile to get started',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white38,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Budget kartı — bu ayın verisi
                  if (_profileSet)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'MONTHLY LIFE BUDGET',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    _monthName(
                                      DateTime.now().month,
                                    ).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              if (isOverBudget)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE57373,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE57373,
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'OVER BUDGET',
                                    style: TextStyle(
                                      color: Color(0xFFE57373),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatHours(_spentHours),
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '/ ${_formatHours(_totalMonthlyHours)}',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$percentage%',
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                barColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                isOverBudget
                                    ? Icons.warning_amber_rounded
                                    : Icons.hourglass_bottom_outlined,
                                color: isOverBudget
                                    ? const Color(0xFFE57373)
                                    : Colors.white38,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOverBudget
                                    ? '+ ${_formatHours(overHours)} over budget this month'
                                    : '${_formatHours(remainingHours)} remaining'
                                          '  ·  $remainingWorkDays wd left',
                                style: TextStyle(
                                  color: isOverBudget
                                      ? const Color(0xFFE57373)
                                      : Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── İki kart yan yana: Scan + Manual ─────────────────────────
                  Row(
                    children: [
                      // Scan Barcode kartı
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _goToScanner,
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2E45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'SCAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Scan a product',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add Manually kartı
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showAddManualDialog,
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            child: Container(
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A2E45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Enter manually',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Recurring card (sadece öneri varsa göster) ────────────────
                  if (_profileSet && _hasRecurringSuggestions) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _showRecurringSheet(isAutoTriggered: false),
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Colors.white.withValues(alpha: 0.1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2E45),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.repeat_rounded,
                                color: Color(0xFF4CAF93),
                                size: 36,
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RECURRING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Suggestions from last month',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white24,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 16),

                  // Recent Scans başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Scans',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: _goToHistory,
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_recentScans.isEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Text('🧾', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          const Text(
                            'No expenses this month',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Scan a barcode or add an entry\nto start tracking your life hours.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._recentScans.map((scan) {
                      final cat = _getCatById(scan['category']);
                      final workDays = _workDaysText(scan['time'] ?? '');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: workDays != null ? 52 : 38,
                              decoration: BoxDecoration(
                                color: cat != null
                                    ? cat['color'] as Color
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scan['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (cat != null) ...[
                                        Text(
                                          cat['icon'] as String,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          cat['label'] as String,
                                          style: TextStyle(
                                            color: cat['color'] as Color,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (workDays != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      workDays,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  scan['time'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  scan['price'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── Manuel entry motivasyon kartı ─────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              top: _showManualCard ? 12 : -200,
              left: 16,
              right: 16,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showManualCard ? 1.0 : 0.0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2E45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Üst satır: emoji + başlık + ✕
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _manualCardEmoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Entry logged ✓',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showManualCard = false),
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white38,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Ana mesaj
                        Text(
                          _manualCardEmoji.isNotEmpty &&
                                  _manualCardMessage.contains('\n\n')
                              ? _manualCardMessage.split('\n\n').first
                              : _manualCardMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // "That's X of your work time" — ayrı vurgu satırı
                        if (_manualCardMessage.contains('\n\n'))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _manualCardMessage.split('\n\n').last,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ), // Stack
      ), // GestureDetector
    );
  }
}

// ── Monthly Report Sheet (self-contained) ─────────────────────────────────
class _MonthlyReportSheet extends StatefulWidget {
  final String currency;
  final double hourlyRate;
  final int dailyHours;
  final double totalMonthlyHours;

  const _MonthlyReportSheet({
    required this.currency,
    required this.hourlyRate,
    required this.dailyHours,
    required this.totalMonthlyHours,
  });

  @override
  State<_MonthlyReportSheet> createState() => _MonthlyReportSheetState();
}

class _MonthlyReportSheetState extends State<_MonthlyReportSheet> {
  bool _showMoney = false;
  bool _aiLoading = true;
  bool _dataLoading = true;
  String _aiComment = '';

  // Hesaplanan veriler
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<DateTime> _availableMonths = [];
  List<Map<String, String>> _allHistory = [];
  List<Map<String, String>> _monthItems = [];
  Map<String, double> _catTotals = {};
  Map<String, double> _catMoneyTotals = {};
  double _totalHours = 0;
  double _totalMoney = 0;
  List<Map<String, String>> _top3 = [];
  Map<String, dynamic> _domCat = {};
  int _domPct = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _fmt(double h) {
    final hours = h.floor();
    final mins = ((h - hours) * 60).round();
    return '${hours}h ${mins}m';
  }

  String _monthName(int m) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[m];
  }

  double _parseH(String t) {
    final h =
        double.tryParse(RegExp(r'(\d+)h').firstMatch(t)?.group(1) ?? '0') ?? 0;
    final m =
        double.tryParse(RegExp(r'(\d+)m').firstMatch(t)?.group(1) ?? '0') ?? 0;
    return h + m / 60;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final items = historyJson
        .map((e) => Map<String, String>.from(jsonDecode(e) as Map))
        .toList();

    // Mevcut ayları bul
    final monthKeys = <String>{};
    for (final item in items) {
      try {
        final dt = DateTime.parse(item['timestamp'] ?? '');
        monthKeys.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}');
      } catch (_) {}
    }
    final months = monthKeys.map((k) {
      final p = k.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]));
    }).toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime(DateTime.now().year, DateTime.now().month);
    setState(() {
      _allHistory = items;
      _availableMonths = months.isEmpty ? [now] : months;
      _selectedMonth = months.isNotEmpty ? months.first : now;
      _dataLoading = false;
    });
    _computeForMonth();
  }

  void _computeForMonth() {
    final sel = _selectedMonth;
    final monthItems = _allHistory.where((item) {
      try {
        final dt = DateTime.parse(item['timestamp'] ?? '');
        return dt.month == sel.month && dt.year == sel.year;
      } catch (_) {
        return false;
      }
    }).toList();

    final catT = <String, double>{};
    final catM = <String, double>{};
    for (final cat in kCategories) {
      catT[cat['id'] as String] = 0;
      catM[cat['id'] as String] = 0;
    }
    for (final item in monthItems) {
      final cat = item['category'] ?? 'living';
      catT[cat] = (catT[cat] ?? 0) + _parseH(item['time'] ?? '');
      final price =
          double.tryParse(
            (item['price'] ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          0;
      catM[cat] = (catM[cat] ?? 0) + price;
    }
    final totalH = catT.values.fold(0.0, (a, b) => a + b);
    final totalM = catM.values.fold(0.0, (a, b) => a + b);

    final sorted = List.of(monthItems)
      ..sort(
        (a, b) => _parseH(b['time'] ?? '').compareTo(_parseH(a['time'] ?? '')),
      );
    final top3 = sorted.take(3).toList();

    Map<String, dynamic> domCat = kCategories[0];
    int domPct = 0;
    if (totalH > 0) {
      final domId = catT.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      domCat = kCategories.firstWhere((c) => c['id'] == domId);
      domPct = (catT[domId]! / totalH * 100).round();
    }

    setState(() {
      _monthItems = monthItems;
      _catTotals = catT;
      _catMoneyTotals = catM;
      _totalHours = totalH;
      _totalMoney = totalM;
      _top3 = top3;
      _domCat = domCat;
      _domPct = domPct;
      _aiLoading = true;
      _aiComment = '';
    });

    if (monthItems.isNotEmpty) {
      _fetchAiComment();
    } else {
      setState(() {
        _aiLoading = false;
        _aiComment = '';
      });
    }
  }

  void _onMonthSelected(DateTime month) {
    if (_selectedMonth == month) return;
    setState(() => _selectedMonth = month);
    _computeForMonth();
  }

  void _showAllMonthsSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            const Text(
              'All Months',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableMonths.skip(3).map((month) {
                    final isSelected =
                        month.month == _selectedMonth.month &&
                        month.year == _selectedMonth.year;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _onMonthSelected(month);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white12,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${_monthName(month.month)} ${month.year}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAiComment() async {
    try {
      final catLines = kCategories
          .map((cat) {
            final h = _catTotals[cat['id']] ?? 0;
            final pct = _totalHours > 0 ? (h / _totalHours * 100).round() : 0;
            return '${cat['label']}: ${_fmt(h)} ($pct%)';
          })
          .join(', ');

      final top3Lines = _top3
          .map((item) => '${item['name']} (${item['time']}, ${item['price']})')
          .join('; ');

      final budgetStatus = _totalHours > widget.totalMonthlyHours
          ? 'OVER BUDGET by ${_fmt(_totalHours - widget.totalMonthlyHours)}'
          : '${_fmt(widget.totalMonthlyHours - _totalHours)} remaining';

      final prompt =
          '''You are a friendly personal finance coach inside a mobile app called LifeHours that tracks spending in work-hours.

The user's monthly spending summary for ${_monthName(_selectedMonth.month)} ${_selectedMonth.year}:
- Total spent: ${_fmt(_totalHours)} out of ${_fmt(widget.totalMonthlyHours)} budget ($budgetStatus)
- Number of purchases: ${_monthItems.length}
- Category breakdown: $catLines
- Top 3 most expensive: $top3Lines
- Dominant category: ${_domCat['label']} (${_domPct}% of spending)
- Hourly rate: ${widget.currency}${widget.hourlyRate.toStringAsFixed(2)}/hr

Write a warm, insightful 3-4 sentence personal commentary in English. Be specific — mention actual category names, percentages, and item names. Point out what's notable. End with one actionable suggestion for next month. Keep it conversational, not preachy. No bullet points, just flowing text.''';

      final response = await _callClaude(prompt);
      if (mounted)
        setState(() {
          _aiComment = response;
          _aiLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _aiComment = 'Unable to load AI insight. Please try again.';
          _aiLoading = false;
        });
    }
  }

  Future<String> _callClaude(String prompt) async {
    const apiKey = 'YOUR_API_KEY_HERE';
    final response = await http
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': 'claude-haiku-4-5-20251001',
            'max_tokens': 300,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));
    debugPrint('AI STATUS: ${response.statusCode}');
    debugPrint('AI BODY: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map;
    return decoded['content'][0]['text'] as String? ?? '';
  }

  void _exportReport() {
    final month = '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}';
    final budgetPct = widget.totalMonthlyHours > 0
        ? (_totalHours / widget.totalMonthlyHours * 100).round()
        : 0;
    final isOver = _totalHours > widget.totalMonthlyHours;

    final sb = StringBuffer();
    sb.writeln('📊 LifeHours — $month Report');
    sb.writeln('═══════════════════════════');
    sb.writeln('');
    sb.writeln('💰 TOTAL SPENT');
    sb.writeln(
      '${_fmt(_totalHours)} of ${_fmt(widget.totalMonthlyHours)} ($budgetPct%)',
    );
    sb.writeln(
      isOver
          ? '⚠️ Over budget by ${_fmt(_totalHours - widget.totalMonthlyHours)}'
          : '✅ ${_fmt(widget.totalMonthlyHours - _totalHours)} remaining',
    );
    sb.writeln(
      '${widget.currency}${_totalMoney.toStringAsFixed(2)} total spend',
    );
    sb.writeln('');
    sb.writeln('📂 CATEGORY BREAKDOWN');
    for (final cat in kCategories) {
      final h = _catTotals[cat['id']] ?? 0;
      final m = _catMoneyTotals[cat['id']] ?? 0;
      if (h == 0) continue;
      final pct = _totalHours > 0 ? (h / _totalHours * 100).round() : 0;
      sb.writeln(
        '${cat['icon']} ${cat['label']}: ${_fmt(h)} ($pct%) — ${widget.currency}${m.toStringAsFixed(2)}',
      );
    }
    sb.writeln('');
    sb.writeln('🏆 TOP EXPENSES');
    for (int i = 0; i < _top3.length; i++) {
      final item = _top3[i];
      sb.writeln(
        '${i + 1}. ${item['name']} — ${item['time']} (${item['price']})',
      );
    }
    if (_aiComment.isNotEmpty && !_aiLoading) {
      sb.writeln('');
      sb.writeln('🤖 AI INSIGHT');
      sb.writeln(_aiComment);
    }
    sb.writeln('');
    sb.writeln('Generated by LifeHours');

    // Share sheet
    _shareText(sb.toString());
  }

  Future<void> _shareText(String text) async {
    try {
      await Share.share(text, subject: 'LifeHours Monthly Report');
    } catch (e) {
      // Fallback: clipboard
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Report copied to clipboard!'),
            backgroundColor: Color(0xFF1A2E45),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dataLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.white38)),
      );
    }

    final budgetPct = widget.totalMonthlyHours > 0
        ? (_totalHours / widget.totalMonthlyHours * 100).round()
        : 0;
    final isOver = _totalHours > widget.totalMonthlyHours;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                children: [
                  // Başlık
                  Row(
                    children: [
                      const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_monthName(_selectedMonth.month)} ${_selectedMonth.year} Report',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_monthItems.length} entries tracked',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // ── Ay seçici: ilk 3 + ··· ─────────────────────────────
                  Row(
                    children: [
                      ...(_availableMonths.take(3).map((month) {
                        final isSelected =
                            month.month == _selectedMonth.month &&
                            month.year == _selectedMonth.year;
                        return Flexible(
                          child: GestureDetector(
                            onTap: () => _onMonthSelected(month),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white12,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${_monthName(month.month)} ${month.year}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      })),
                      if (_availableMonths.length > 3)
                        GestureDetector(
                          onTap: () => _showAllMonthsSheet(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _availableMonths
                                      .skip(3)
                                      .any(
                                        (m) =>
                                            m.month == _selectedMonth.month &&
                                            m.year == _selectedMonth.year,
                                      )
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    _availableMonths
                                        .skip(3)
                                        .any(
                                          (m) =>
                                              m.month == _selectedMonth.month &&
                                              m.year == _selectedMonth.year,
                                        )
                                    ? Colors.white
                                    : Colors.white12,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _availableMonths
                                          .skip(3)
                                          .any(
                                            (m) =>
                                                m.month ==
                                                    _selectedMonth.month &&
                                                m.year == _selectedMonth.year,
                                          )
                                      ? '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}'
                                      : '···',
                                  style: TextStyle(
                                    color:
                                        _availableMonths
                                            .skip(3)
                                            .any(
                                              (m) =>
                                                  m.month ==
                                                      _selectedMonth.month &&
                                                  m.year == _selectedMonth.year,
                                            )
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight:
                                        _availableMonths
                                            .skip(3)
                                            .any(
                                              (m) =>
                                                  m.month ==
                                                      _selectedMonth.month &&
                                                  m.year == _selectedMonth.year,
                                            )
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white38,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_monthItems.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No entries for this month.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                    ),
                  ] else ...[
                    // ── Budget özeti ────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOver
                              ? const Color(0xFFE57373).withValues(alpha: 0.4)
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL SPENT',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fmt(_totalHours),
                                  style: TextStyle(
                                    color: isOver
                                        ? const Color(0xFFE57373)
                                        : _totalHours /
                                                  widget.totalMonthlyHours <
                                              0.5
                                        ? const Color(0xFF4CAF93)
                                        : _totalHours /
                                                  widget.totalMonthlyHours <
                                              0.8
                                        ? const Color(0xFFF5A623)
                                        : const Color(0xFFE57373),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${widget.currency}${_totalMoney.toStringAsFixed(2)}  ·  of ${_fmt(widget.totalMonthlyHours)} budget',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isOver
                                  ? const Color(
                                      0xFFE57373,
                                    ).withValues(alpha: 0.15)
                                  : _totalHours / widget.totalMonthlyHours < 0.5
                                  ? const Color(
                                      0xFF4CAF93,
                                    ).withValues(alpha: 0.15)
                                  : _totalHours / widget.totalMonthlyHours < 0.8
                                  ? const Color(
                                      0xFFF5A623,
                                    ).withValues(alpha: 0.15)
                                  : const Color(
                                      0xFFE57373,
                                    ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$budgetPct%',
                              style: TextStyle(
                                color: isOver
                                    ? const Color(0xFFE57373)
                                    : _totalHours / widget.totalMonthlyHours <
                                          0.5
                                    ? const Color(0xFF4CAF93)
                                    : _totalHours / widget.totalMonthlyHours <
                                          0.8
                                    ? const Color(0xFFF5A623)
                                    : const Color(0xFFE57373),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Kategori dağılımı ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CATEGORY BREAKDOWN',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showMoney = !_showMoney),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _showMoney ? '⏱' : '💶',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showMoney ? 'Show time' : 'Show money',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...kCategories.map((cat) {
                      final h = _catTotals[cat['id']] ?? 0;
                      final money = _catMoneyTotals[cat['id']] ?? 0;
                      if (h == 0 && money == 0) return const SizedBox.shrink();
                      final pct = _showMoney
                          ? (_totalMoney > 0
                                ? (money / _totalMoney * 100).round()
                                : 0)
                          : (_totalHours > 0
                                ? (h / _totalHours * 100).round()
                                : 0);
                      final barVal = _showMoney
                          ? (_totalMoney > 0 ? money / _totalMoney : 0.0)
                          : (_totalHours > 0 ? h / _totalHours : 0.0);
                      final color = cat['color'] as Color;
                      final label = _showMoney
                          ? '${widget.currency}${money.toStringAsFixed(0)}'
                          : '$pct%';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              cat['icon'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Text(
                                cat['label'] as String,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: barVal.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 56,
                              child: Text(
                                label,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // ── Top 3 ───────────────────────────────────────────────
                    const Text(
                      'TOP EXPENSES',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._top3.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final cat = kCategories.firstWhere(
                        (c) => c['id'] == item['category'],
                        orElse: () => kCategories[0],
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: (cat['color'] as Color).withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: cat['color'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _showMoney
                                      ? (item['price'] ?? '')
                                      : (item['time'] ?? ''),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _showMoney
                                      ? (item['time'] ?? '')
                                      : (item['price'] ?? ''),
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // ── AI Insight ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (_domCat['color'] as Color? ??
                                    const Color(0xFF4A90D9))
                                .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              (_domCat['color'] as Color? ??
                                      const Color(0xFF4A90D9))
                                  .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                (_domCat['icon'] as String?) ?? '📊',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'AI INSIGHT',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_aiLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white38,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _aiLoading
                              ? const Text(
                                  'Analyzing your spending...',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  _aiComment,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ], // end of non-empty month content
                  // ── Export butonu ───────────────────────────────────────
                  if (_monthItems.isNotEmpty)
                    Material(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _exportReport,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.ios_share_outlined,
                                color: Colors.white54,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Export Report',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
