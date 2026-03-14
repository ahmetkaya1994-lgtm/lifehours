import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

const List<String> kRecurringCategories = ['living', 'health', 'education'];

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> _history = [];
  String _currency = '\$';
  double _totalMonthlyHours = 0;
  int _dailyHours = 8;
  String _selectedFilter = 'all';
  String _sourceFilter = 'all';

  late DateTime _selectedMonth;
  List<DateTime> _availableMonths = [];

  final PageController _chartPageController = PageController();
  int _chartPage = 0;
  bool _chartShowMoney = false;

  @override
  void dispose() {
    _chartPageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyHours = prefs.getInt('daily_hours') ?? 8;
    const workDaysPerMonth = 22.0;
    final totalHours = workDaysPerMonth * dailyHours;

    final historyJson = prefs.getStringList('scan_history') ?? [];
    final List<Map<String, String>> items = [];
    final Set<String> monthKeys = {};

    for (final item in historyJson) {
      final map = jsonDecode(item) as Map;
      items.add(Map<String, String>.from(map));
      try {
        final dt = DateTime.parse(map['timestamp'] as String? ?? '');
        monthKeys.add('${dt.year}-${dt.month.toString().padLeft(2, '0')}');
      } catch (_) {}
    }

    final months = monthKeys.map((k) {
      final parts = k.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]));
    }).toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime(DateTime.now().year, DateTime.now().month);
    if (!months.any(
      (m) => m.year == _selectedMonth.year && m.month == _selectedMonth.month,
    )) {
      _selectedMonth = now;
    }

    setState(() {
      _currency = prefs.getString('currency') ?? '\$';
      _totalMonthlyHours = totalHours;
      _dailyHours = dailyHours;
      _history = items;
      _availableMonths = months.isEmpty ? [now] : months;
    });
  }

  List<Map<String, String>> get _monthHistory {
    return _history.where((item) {
      try {
        final dt = DateTime.parse(item['timestamp'] ?? '');
        return dt.month == _selectedMonth.month &&
            dt.year == _selectedMonth.year;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get _spentHours => _monthHistory.fold(
    0.0,
    (sum, item) => sum + _parseHours(item['time'] ?? ''),
  );

  double _parseHours(String timeStr) {
    final hMatch = RegExp(r'(\d+)h').firstMatch(timeStr);
    final mMatch = RegExp(r'(\d+)m').firstMatch(timeStr);
    final h = double.tryParse(hMatch?.group(1) ?? '0') ?? 0;
    final m = double.tryParse(mMatch?.group(1) ?? '0') ?? 0;
    return h + (m / 60);
  }

  double _hoursForCategory(String categoryId) {
    return _monthHistory
        .where((item) => item['category'] == categoryId)
        .fold(0.0, (sum, item) => sum + _parseHours(item['time'] ?? ''));
  }

  double _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  double _moneyForCategory(String categoryId) {
    return _monthHistory
        .where((item) => item['category'] == categoryId)
        .fold(0.0, (sum, item) => sum + _parsePrice(item['price'] ?? ''));
  }

  bool get _isOlderMonthSelected {
    return _availableMonths
        .skip(3)
        .any(
          (m) =>
              m.month == _selectedMonth.month && m.year == _selectedMonth.year,
        );
  }

  String _shortMonthLabel(DateTime dt) {
    const short = [
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
    return '${short[dt.month]} ${dt.year}';
  }

  int _countForMonth(DateTime month) {
    return _history.where((item) {
      try {
        final dt = DateTime.parse(item['timestamp'] ?? '');
        return dt.month == month.month && dt.year == month.year;
      } catch (_) {
        return false;
      }
    }).length;
  }

  void _showAllMonthsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2E45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
                'Past Months',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._availableMonths.skip(3).map((month) {
                final isSelected =
                    month.month == _selectedMonth.month &&
                    month.year == _selectedMonth.year;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMonth = month);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white12,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white38,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _monthLabel(month),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_countForMonth(month)} entries',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, String> scan) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final idx = historyJson.indexWhere((itemStr) {
      final map = jsonDecode(itemStr) as Map;
      return map['timestamp'] == scan['timestamp'];
    });
    if (idx == -1) return;
    historyJson.removeAt(idx);
    await prefs.setStringList('scan_history', historyJson);
    _loadData();
  }

  Future<void> _editItem(Map<String, String> scan) async {
    final nameController = TextEditingController(text: scan['name']);
    final priceController = TextEditingController(
      text: scan['price']?.replaceAll(RegExp(r'[^\d.]'), '') ?? '',
    );
    String selectedCategory = scan['category'] ?? 'living';
    final prefs = await SharedPreferences.getInstance();
    final hourlyRate = prefs.getDouble('hourly_rate') ?? 0;
    DateTime pickedDate = () {
      try {
        return DateTime.parse(scan['timestamp'] ?? '');
      } catch (_) {
        return DateTime.now();
      }
    }();

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
                    'Edit Entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'NAME',
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
                        hintText: 'Product name',
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
                    'PRICE',
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
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                  const SizedBox(height: 16),
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
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: pickedDate,
                        firstDate: DateTime(now.year - 5),
                        lastDate: now,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.white,
                              onPrimary: Color(0xFF0D1B2A),
                              surface: Color(0xFF1A2E45),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() {
                          pickedDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            pickedDate.hour,
                            pickedDate.minute,
                          );
                        });
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
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final price =
                            double.tryParse(priceController.text) ?? 0;
                        if (price <= 0) return;
                        final newHours = hourlyRate > 0
                            ? price / hourlyRate
                            : 0.0;
                        final h = newHours.floor();
                        final m = ((newHours - h) * 60).round();
                        final historyJson =
                            prefs.getStringList('scan_history') ?? [];
                        final idx = historyJson.indexWhere((itemStr) {
                          final map = jsonDecode(itemStr) as Map;
                          return map['timestamp'] == scan['timestamp'];
                        });
                        if (idx != -1) {
                          final updatedItem = {
                            'name': nameController.text.isEmpty
                                ? 'Unknown'
                                : nameController.text,
                            'price': '$_currency${price.toStringAsFixed(2)}',
                            'time': '${h}h ${m}m',
                            'category': selectedCategory,
                            'timestamp': pickedDate.toIso8601String(),
                          };
                          historyJson[idx] = jsonEncode(updatedItem);
                          await prefs.setStringList(
                            'scan_history',
                            historyJson,
                          );
                        }
                        if (mounted) Navigator.pop(context);
                        _loadData();
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Center(
                          child: Text(
                            'SAVE CHANGES',
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

  Future<void> _clearMonth() async {
    final entries = _monthHistory;
    final entryCount = entries.length;
    final totalHours = _spentHours;
    final totalMoney = entries.fold(
      0.0,
      (sum, item) => sum + _parsePrice(item['price'] ?? ''),
    );
    final hh = totalHours.floor();
    final mm = ((totalHours - hh) * 60).round();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear ${_monthLabel(_selectedMonth)}?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _clearStatRow('🗑', '$entryCount entries will be removed'),
                  const SizedBox(height: 10),
                  _clearStatRow('⏱', '${hh}h ${mm}m of tracked time'),
                  const SizedBox(height: 10),
                  _clearStatRow(
                    '💶',
                    '$_currency${totalMoney.toStringAsFixed(2)} total spend',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'This cannot be undone.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('scan_history') ?? [];
      final filtered = historyJson.where((itemStr) {
        try {
          final map = jsonDecode(itemStr) as Map;
          final dt = DateTime.parse(map['timestamp'] as String? ?? '');
          return !(dt.month == _selectedMonth.month &&
              dt.year == _selectedMonth.year);
        } catch (_) {
          return true;
        }
      }).toList();
      await prefs.setStringList('scan_history', filtered);
      _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      _loadData();
    }
  }

  Widget _clearStatRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatHours(double totalHours) {
    final h = totalHours.floor();
    final m = ((totalHours - h) * 60).round();
    return '${h}h ${m}m';
  }

  String? _workDaysText(String timeStr) {
    final hours = _parseHours(timeStr);
    if (_dailyHours <= 0 || hours < _dailyHours) return null;
    final days = hours / _dailyHours;
    return '🗓 ${days.toStringAsFixed(1)} work days';
  }

  String? _categoryWorkDays(double hours) {
    if (_dailyHours <= 0 || hours < _dailyHours) return null;
    final days = hours / _dailyHours;
    return '· ${days.toStringAsFixed(1)} wd';
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year)
        return 'Today';
      if (dt.day == now.day - 1 && dt.month == now.month) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
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

  Map<String, dynamic>? _getCatById(String? id) {
    try {
      return kCategories.firstWhere((c) => c['id'] == id);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, String>> get _filteredHistory {
    return _monthHistory.where((item) {
      if (_selectedFilter != 'all' && item['category'] != _selectedFilter) return false;
      if (_sourceFilter != 'all' && (item['source'] ?? 'manual') != _sourceFilter) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final spentHours = _spentHours;
    final isCurrentMonth =
        _selectedMonth.month == DateTime.now().month &&
        _selectedMonth.year == DateTime.now().year;
    final isOverBudget = isCurrentMonth && spentHours > _totalMonthlyHours;
    final overHours = spentHours - _totalMonthlyHours;
    final progress = _totalMonthlyHours > 0
        ? (spentHours / _totalMonthlyHours).clamp(0.0, 1.0)
        : 0.0;
    final remainingHours = (_totalMonthlyHours - spentHours).clamp(
      0.0,
      double.infinity,
    );
    final percentage = _totalMonthlyHours > 0
        ? (spentHours / _totalMonthlyHours * 100).round()
        : 0;
    final barColor = progress < 0.5
        ? const Color(0xFF4CAF93)
        : progress < 0.8
        ? const Color(0xFFF5A623)
        : const Color(0xFFE57373);

    final categoryHours = {
      for (final cat in kCategories)
        cat['id'] as String: _hoursForCategory(cat['id'] as String),
    };
    final maxCatHours = categoryHours.values.fold(0.0, (a, b) => a > b ? a : b);
    final totalSpentHours = categoryHours.values.fold(0.0, (a, b) => a + b);
    final filtered = _filteredHistory;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_monthHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white54),
              onPressed: _clearMonth,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Row(
            children: [
              ...(_availableMonths.take(3).map((month) {
                final isSelected =
                    month.month == _selectedMonth.month &&
                    month.year == _selectedMonth.year;
                return Flexible(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMonth = month),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.15)
                            : const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white12,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _monthLabel(month),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
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
                  onTap: _showAllMonthsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _isOlderMonthSelected
                          ? Colors.white.withValues(alpha: 0.15)
                          : const Color(0xFF1A2E45),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isOlderMonthSelected
                            ? Colors.white
                            : Colors.white12,
                        width: _isOlderMonthSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isOlderMonthSelected
                              ? _shortMonthLabel(_selectedMonth)
                              : '···',
                          style: TextStyle(
                            color: _isOlderMonthSelected
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: _isOlderMonthSelected
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

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                          _monthLabel(_selectedMonth).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    if (!isCurrentMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '📅 Past month',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    if (isOverBudget)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE57373).withValues(alpha: 0.4),
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
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatHours(spentHours),
                      style: TextStyle(
                        color: barColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '/ ${_formatHours(_totalMonthlyHours)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isOverBudget
                          ? Icons.warning_amber_rounded
                          : isCurrentMonth
                          ? Icons.hourglass_bottom_outlined
                          : Icons.check_circle_outline,
                      color: isOverBudget
                          ? const Color(0xFFE57373)
                          : Colors.white38,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOverBudget
                          ? '+ ${_formatHours(overHours)} over budget this month'
                          : isCurrentMonth
                          ? '${_formatHours(remainingHours)} remaining this month${_dailyHours > 0 && remainingHours >= _dailyHours ? ' · ${(remainingHours / _dailyHours).toStringAsFixed(1)} wd' : ''}'
                          : 'Final: ${_formatHours(spentHours)} spent',
                      style: TextStyle(
                        color: isOverBudget
                            ? const Color(0xFFE57373)
                            : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [0, 1]
                        .map(
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            width: _chartPage == i ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _chartPage == i
                                  ? Colors.white70
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (_chartPage == 1)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _chartShowMoney = !_chartShowMoney),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _chartShowMoney ? '💶' : '⏱',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _chartShowMoney ? 'Money' : 'Hours',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.swap_horiz,
                              color: Colors.white38,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 295,
                child: PageView(
                  controller: _chartPageController,
                  onPageChanged: (p) => setState(() => _chartPage = p),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CATEGORY BREAKDOWN',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...kCategories.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final cat = entry.value;
                            final catId = cat['id'] as String;
                            final hours = categoryHours[catId] ?? 0;
                            final catProgress = maxCatHours > 0
                                ? hours / maxCatHours
                                : 0.0;
                            final color = cat['color'] as Color;
                            final wdText = _categoryWorkDays(hours);
                            final isLast = idx == kCategories.length - 1;
                            return Padding(
                              padding: EdgeInsets.only(bottom: isLast ? 4 : 12),
                              child: Row(
                                children: [
                                  Text(
                                    cat['icon'] as String,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 68,
                                    child: Text(
                                      cat['label'] as String,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: catProgress,
                                        minHeight: 10,
                                        backgroundColor: Colors.white12,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 56,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _formatHours(hours),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (wdText != null)
                                          Text(
                                            wdText,
                                            style: const TextStyle(
                                              color: Colors.white24,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (totalSpentHours > 0) ...[
                            const Divider(color: Colors.white10, height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Builder(builder: (_) {
                                  final topCat = kCategories.reduce((a, b) =>
                                      (categoryHours[a['id']] ?? 0) >
                                              (categoryHours[b['id']] ?? 0)
                                          ? a
                                          : b);
                                  final topHours = categoryHours[topCat['id']] ?? 0;
                                  final pct = totalSpentHours > 0
                                      ? (topHours / totalSpentHours * 100).round()
                                      : 0;
                                  return Row(
                                    children: [
                                      Text(
                                        topCat['icon'] as String,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${topCat['label']} leads at $pct%',
                                        style: TextStyle(
                                          color: topCat['color'] as Color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                Text(
                                  '${_formatHours(totalSpentHours)} total',
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2E45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _chartShowMoney
                                ? 'SPENDING BY CATEGORY'
                                : 'TIME BY CATEGORY',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _chartShowMoney
                                ? 'Total: $_currency${_monthHistory.fold(0.0, (s, i) => s + _parsePrice(i["price"] ?? "")).toStringAsFixed(0)}'
                                : 'Total: ${_formatHours(totalSpentHours)}',
                            style: TextStyle(
                              color: barColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: _buildBarChart(categoryHours, barColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', 'All', null, null),
                ...kCategories.map(
                  (cat) => _filterChip(
                    cat['id'] as String,
                    cat['label'] as String,
                    cat['icon'] as String,
                    cat['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedFilter == 'all'
                    ? 'All Entries'
                    : kCategories.firstWhere(
                            (c) => c['id'] == _selectedFilter,
                          )['label']
                          as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${filtered.length} items',
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '← Swipe left to edit or delete',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2E45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(
                    isCurrentMonth ? '📭' : '🗂️',
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCurrentMonth
                        ? 'No entries this month yet'
                        : 'No entries for ${_monthLabel(_selectedMonth)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCurrentMonth
                        ? 'Add your first expense to\nstart seeing your history here.'
                        : 'There are no recorded expenses\nfor this period.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(filtered.length, (i) {
              final scan = filtered[i];
              final cat = _getCatById(scan['category']);
              final workDays = _workDaysText(scan['time'] ?? '');

              return Dismissible(
                key: ValueKey('${scan['timestamp'] ?? ''}_$i'),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showModalBottomSheet<bool>(
                        context: context,
                        backgroundColor: const Color(0xFF1A2E45),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (ctx) => Padding(
                          padding: const EdgeInsets.all(24),
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
                              const SizedBox(height: 16),
                              Text(
                                scan['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Material(
                                color: const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.pop(ctx, false);
                                    _editItem(scan);
                                  },
                                  child: const SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit Entry',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => Navigator.pop(ctx, true),
                                  child: Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
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
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  // Önce state'den kaldır — widget tree hemen güncellenir
                  setState(() {
                    _history.removeWhere(
                      (item) => item['timestamp'] == scan['timestamp'],
                    );
                  });
                  // Sonra SharedPreferences'dan sil
                  _deleteItem(scan);
                },
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
                child: Container(
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
                        height: workDays != null ? 52 : 40,
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    scan['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if ((scan['source'] ?? 'manual') ==
                                    'barcode') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4A90D9,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4A90D9,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Text(
                                      '📷',
                                      style: TextStyle(fontSize: 9),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
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
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _formatDate(scan['timestamp']),
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            if (workDays != null) ...[
                              const SizedBox(height: 3),
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
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    Map<String, double> categoryHours,
    Color totalBarColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelTopH = 18.0;
        const labelBottomH = 44.0;
        final maxBarHeight = constraints.maxHeight - labelTopH - labelBottomH;

        final values = kCategories.map((cat) {
          final catId = cat['id'] as String;
          return _chartShowMoney
              ? _moneyForCategory(catId)
              : (categoryHours[catId] ?? 0.0);
        }).toList();

        final maxVal = values.fold(0.0, (a, b) => a > b ? a : b);

        return Column(
          children: [
            SizedBox(
              height: labelTopH + maxBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(kCategories.length, (i) {
                  final cat = kCategories[i];
                  final color = cat['color'] as Color;
                  final val = values[i];
                  final barH = maxVal > 0
                      ? ((val / maxVal) * maxBarHeight).clamp(4.0, maxBarHeight)
                      : 4.0;
                  final labelStr = _chartShowMoney
                      ? (val >= 1000
                            ? '${(val / 1000).toStringAsFixed(1)}k'
                            : val.toStringAsFixed(0))
                      : (val >= 1
                            ? '${val.floor()}h'
                            : val > 0
                            ? '${(val * 60).round()}m'
                            : '');

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: labelTopH,
                            child: Center(
                              child: Text(
                                labelStr,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            width: double.infinity,
                            height: barH,
                            decoration: BoxDecoration(
                              color: val > 0
                                  ? color.withValues(alpha: 0.85)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(
              height: labelBottomH,
              child: Row(
                children: kCategories
                    .map(
                      (cat) => Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              cat['icon'] as String,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              (cat['label'] as String)
                                  .substring(0, 3)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sourceToggle(String value, String label) {
    final isSelected = _sourceFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _sourceFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFF1A2E45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white54 : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String id, String label, String? icon, Color? color) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.white).withValues(alpha: 0.15)
              : const Color(0xFF1A2E45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (color ?? Colors.white) : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? (color ?? Colors.white) : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
