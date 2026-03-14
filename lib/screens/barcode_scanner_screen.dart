import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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

const Map<String, List<String>> kAwarenessMessages = {
  'living': [
    "Do you already have something similar at home?",
    "Do you really need this right now, or are you just bored?",
    "Are you buying this just because it's on sale?",
    "Stockpiling is sometimes waste, not savings.",
    "Would you still want this tomorrow?",
    "You're about to go off-list — take a deep breath.",
    "Is this worth the hours you worked for it?",
    "A healthy choice! Your body will thank you. 💚",
    "Check the expiry date — buying in bulk only saves if you use it.",
    "Is this a habit purchase, or a conscious one?",
    "Could you borrow this instead of buying it?",
    "Have you checked if you already have this at home?",
    "Is this a want or a genuine need right now?",
    "Buying quality over quantity saves money long-term.",
    "Think about how often you'll actually use this.",
    "Is this on your shopping list, or did it catch your eye?",
    "Every unplanned purchase adds up over the month.",
    "A full fridge doesn't mean you need to fill it further.",
    "Convenience costs more — is it worth it this time?",
    "Your future self will thank you for buying only what you need.",
  ],
  'fun': [
    "Will you remember this moment for life? If yes, go for it! 🎉",
    "Are you only going because everyone else is?",
    "Experiences make you happier for longer than things.",
    "We work to enjoy life — sometimes you should enjoy the fruits.",
    "When did you last check your digital subscriptions?",
    "When it's over, what will remain — in your wallet or in your heart?",
    "Is this instant pleasure, or real joy?",
    "If it feeds your soul, it's worth every cent. 😊",
    "Are you going to be fully present, or just scroll through your phone?",
    "Shared experiences with people you love are priceless.",
    "Is this something you've been genuinely looking forward to?",
    "Will this still feel worth it when you check your bank statement?",
    "Fun is essential — just make sure it's actually fun for you.",
    "Are you treating yourself, or escaping something?",
    "The best entertainment is often free — have you considered alternatives?",
    "Is this a planned treat, or an impulse?",
    "Joy is worth investing in — just invest wisely.",
    "How often do you actually use this type of entertainment?",
    "Would you rate this experience 8/10 or higher afterward?",
    "Life is short — spend it on things that genuinely make you happy.",
  ],
  'shopping': [
    "Will this item still excite you next year?",
    "Can you style it with at least 3 things already in your wardrobe?",
    "Don't you already have something similar in your closet?",
    "It's not the discount rate, it's the usage rate that makes you richer.",
    "Once the tag is off, the value drops — will your happiness rise?",
    "Are you following a trend, or expressing your own style?",
    "Feel the quality — is it worth the time you paid for it?",
    "Treating yourself is great — but is this the right piece?",
    "Could you sleep on this decision and come back tomorrow?",
    "Is this filling a genuine gap in your wardrobe, or just filling space?",
    "How many times per week will you actually wear this?",
    "A capsule wardrobe beats a crowded one every time.",
    "Are you buying this because it fits, or because it was 'too good to pass up'?",
    "The best outfit is the one that makes you feel like yourself.",
    "Do you love it, or do you just like it?",
    "Would you buy this at full price? If not, it might not be worth it at any price.",
    "Fast fashion costs the planet and your wallet — is this built to last?",
    "Buying less but better is the smartest wardrobe strategy.",
    "Consider the cost-per-wear: price divided by times you'll wear it.",
    "Your wardrobe is your living space — curate it with intention.",
  ],
  'education': [
    "Investing in yourself is the highest-interest deposit you can make. 📈",
    "This knowledge will multiply the value of every hour you spend.",
    "Don't let the unread books on your shelf get lonely — finish those first?",
    "This isn't an expense, it's capital for your future self.",
    "Are you buying to know it, or to actually apply it?",
    "Never stop feeding your curiosity. 🌱",
    "The learning process is more rewarding than the buying process.",
    "Every minute spent growing your mind is time well spent.",
    "Have you blocked time in your calendar to actually use this?",
    "Knowledge compounds — the earlier you start, the richer the return.",
    "Will you complete this, or will it join the unfinished pile?",
    "The best investment is the one you actually follow through on.",
    "Are you buying this to feel productive, or to actually be productive?",
    "One great book applied beats ten books left unread.",
    "Skills pay dividends long after the initial investment.",
    "Is there a free version of this knowledge available?",
    "Learning without application is just entertainment.",
    "What specifically will you do differently after this?",
    "The best teachers are often the cheapest — curiosity and practice.",
    "This is worth it if you commit to finishing it. Will you?",
  ],
  'health': [
    "Every penny spent on your health adds an hour to your life. 💚",
    "The best equipment is the one you already use.",
    "Equipment doesn't make you an athlete — training does. Start!",
    "Your body is your only home — you're taking good care of it. 🏡",
    "Movement is the greatest luxury. Investing in it is wonderful.",
    "If you're ready to sweat, this expense is well earned.",
    "If the gear at home is gathering dust, you might not need new ones.",
    "Is this for performance, or just to look the part?",
    "Prevention is cheaper than cure — this is a wise investment.",
    "Your health is the foundation everything else is built on.",
    "Will this actually change your routine, or just your intentions?",
    "The best workout is the one you'll actually do consistently.",
    "Are you solving a real problem, or just buying motivation?",
    "Consistency beats expensive equipment every single time.",
    "Investing in sleep, nutrition, and movement pays the best returns.",
    "Is this an upgrade you've earned, or a shortcut you're hoping for?",
    "Health is not a destination — it's a daily practice.",
    "The gym you go to beats the gym you don't, every time.",
    "Will this become a habit, or a guilty reminder on your shelf?",
    "Taking care of yourself is never a waste of money. 💪",
  ],
};

const Map<String, String> kRepeatMessages = {
  'living': "3rd Living expense today... Did you check your shopping list? 🛒",
  'fun': "3rd Fun expense today... Maybe take a little break? 😄",
  'shopping': "3rd Shopping expense today... Is the closet getting full? 👕",
  'education':
      "3rd Education expense today... Did you finish the last course? 📚",
  'health':
      "3rd Health expense today... You're really taking great care of yourself! 💪",
};

// ── Multi-source Product Lookup ────────────────────────────────────────────
class ProductInfo {
  final String name;
  final String? brand;
  final String? source;

  ProductInfo({required this.name, this.brand, this.source});
}

Future<ProductInfo?> fetchProductInfo(String barcode) async {
  // 1️⃣ Open Food Facts — gıda
  final food = await _fetchOpenFoodFacts(barcode);
  if (food != null) return food;

  // 2️⃣ Open Beauty Facts — kozmetik
  final beauty = await _fetchOpenBeautyFacts(barcode);
  if (beauty != null) return beauty;

  // 3️⃣ UPCitemdb — giyim dahil genel
  final upc = await _fetchUPCitemdb(barcode);
  if (upc != null) return upc;

  return null;
}

Future<ProductInfo?> _fetchOpenFoodFacts(String barcode) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final uri = Uri.parse(
      'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
    );
    final req = await client.getUrl(uri);
    req.headers.set('User-Agent', 'LifeHours/1.0');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['status'] != 1) return null;
    final p = data['product'] as Map<String, dynamic>?;
    if (p == null) return null;
    final name =
        (p['product_name_en'] as String?)?.trim() ??
        (p['product_name'] as String?)?.trim() ??
        (p['generic_name'] as String?)?.trim() ??
        '';
    if (name.isEmpty) return null;
    final brand = (p['brands'] as String?)?.split(',').first.trim();
    return ProductInfo(name: name, brand: brand, source: 'food');
  } catch (_) {
    return null;
  }
}

Future<ProductInfo?> _fetchOpenBeautyFacts(String barcode) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final uri = Uri.parse(
      'https://world.openbeautyfacts.org/api/v0/product/$barcode.json',
    );
    final req = await client.getUrl(uri);
    req.headers.set('User-Agent', 'LifeHours/1.0');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    final data = jsonDecode(body) as Map<String, dynamic>;
    if (data['status'] != 1) return null;
    final p = data['product'] as Map<String, dynamic>?;
    if (p == null) return null;
    final name =
        (p['product_name_en'] as String?)?.trim() ??
        (p['product_name'] as String?)?.trim() ??
        '';
    if (name.isEmpty) return null;
    final brand = (p['brands'] as String?)?.split(',').first.trim();
    return ProductInfo(name: name, brand: brand, source: 'beauty');
  } catch (_) {
    return null;
  }
}

Future<ProductInfo?> _fetchUPCitemdb(String barcode) async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    final uri = Uri.parse(
      'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
    );
    final req = await client.getUrl(uri);
    req.headers.set('User-Agent', 'LifeHours/1.0');
    req.headers.set('Accept', 'application/json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    client.close();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final items = data['items'] as List?;
    if (items == null || items.isEmpty) return null;
    final item = items.first as Map<String, dynamic>;
    final name = (item['title'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    final brand = (item['brand'] as String?)?.trim();
    return ProductInfo(name: name, brand: brand, source: 'general');
  } catch (_) {
    return null;
  }
}
// ──────────────────────────────────────────────────────────────────────────

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;
  double _hourlyRate = 0;
  String _currency = '\$';
  int _dailyHours = 8;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hourlyRate = prefs.getDouble('hourly_rate') ?? 0;
      _currency = prefs.getString('currency') ?? '\$';
      _dailyHours = prefs.getInt('daily_hours') ?? 8;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<int> _todayCountForCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final today = DateTime.now();
    int count = 0;
    for (final item in historyJson) {
      final map = jsonDecode(item) as Map;
      if (map['category'] == categoryId) {
        try {
          final dt = DateTime.parse(map['timestamp'] as String);
          if (dt.day == today.day &&
              dt.month == today.month &&
              dt.year == today.year)
            count++;
        } catch (_) {}
      }
    }
    return count;
  }

  Future<String> _getAwarenessMessage(String categoryId) async {
    final count = await _todayCountForCategory(categoryId);
    if (count >= 2) return kRepeatMessages[categoryId] ?? '';
    final messages = kAwarenessMessages[categoryId] ?? [];
    if (messages.isEmpty) return '';
    return messages[Random().nextInt(messages.length)];
  }

  Future<void> _saveToHistory(
    String name,
    double price,
    int hours,
    int minutes,
    String categoryId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('scan_history') ?? [];
    final item = {
      'name': name.isEmpty ? 'Unknown Product' : name,
      'price': '$_currency${price.toStringAsFixed(2)}',
      'time': '${hours}h ${minutes}m',
      'category': categoryId,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'barcode',
    };
    historyJson.insert(0, jsonEncode(item));
    if (historyJson.length > 50) historyJson.removeLast();
    await prefs.setStringList('scan_history', historyJson);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    setState(() => _scanned = true);
    _controller.stop();
    _showPriceDialog(barcode!.rawValue!);
  }

  void _showPriceDialog(String barcode) {
    final priceController = TextEditingController();
    final nameController = TextEditingController();
    String selectedCategory = 'living';
    int quantity = 1;
    bool lookupDone = false;
    bool isLookingUp = true;
    bool sheetOpen = true;
    ProductInfo? foundProduct;

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
            // API lookup — sadece bir kez
            if (!lookupDone) {
              lookupDone = true;
              fetchProductInfo(barcode).then((info) {
                if (!sheetOpen) return;
                setModalState(() {
                  isLookingUp = false;
                  foundProduct = info;
                  if (info != null) {
                    nameController.text = info.brand != null
                        ? '${info.name} - ${info.brand}'
                        : info.name;
                  }
                });
              });
            }

            final unitPrice = double.tryParse(priceController.text) ?? 0;
            final totalPrice = unitPrice * quantity;

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
                  const SizedBox(height: 18),

                  // Başlık + spinner
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Barcode Scanned! ✅',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isLookingUp)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    barcode,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // Ürün adı + "Found" badge
                  Row(
                    children: [
                      const Text(
                        'PRODUCT NAME',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (!isLookingUp && foundProduct != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF93).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF4CAF93).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                foundProduct!.source == 'food'
                                    ? '🥦'
                                    : foundProduct!.source == 'beauty'
                                    ? '💄'
                                    : '🏷️',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'Found',
                                style: TextStyle(
                                  color: Color(0xFF4CAF93),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!isLookingUp && foundProduct == null) ...[
                        const SizedBox(width: 8),
                        const Text(
                          '(optional)',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ],
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
                      border: Border.all(
                        color: (!isLookingUp && foundProduct != null)
                            ? const Color(0xFF4CAF93).withValues(alpha: 0.4)
                            : Colors.white24,
                      ),
                    ),
                    child: TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'e.g. Nike Air Max',
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kategori
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

                  // Fiyat + Quantity
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRODUCT PRICE',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 28,
                                    color: Colors.white12,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: priceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      autofocus: true,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        hintText: '0.00',
                                        hintStyle: TextStyle(
                                          color: Colors.white24,
                                          fontSize: 20,
                                        ),
                                      ),
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QUANTITY',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1B2A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (quantity > 1)
                                        setModalState(() => quantity--);
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: quantity > 1
                                            ? Colors.white12
                                            : Colors.white.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.remove,
                                        color: quantity > 1
                                            ? Colors.white70
                                            : Colors.white24,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        setModalState(() => quantity++),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (quantity > 1 && unitPrice > 0) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          color: Colors.white38,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$quantity x $_currency${unitPrice.toStringAsFixed(2)} = '
                          '$_currency${totalPrice.toStringAsFixed(2)} total',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final price =
                            double.tryParse(priceController.text) ?? 0;
                        if (price <= 0) return;
                        final finalPrice = price * quantity;
                        Navigator.pop(context);
                        _showResultScreen(
                          barcode,
                          finalPrice,
                          nameController.text.trim(),
                          selectedCategory,
                          quantity: quantity,
                          unitPrice: price,
                        );
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: Center(
                          child: Text(
                            'CALCULATE',
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
    ).whenComplete(() {
      sheetOpen = false;
      priceController.dispose();
      nameController.dispose();
      if (mounted) {
        setState(() => _scanned = false);
        _controller.start();
      }
    });
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

  void _showResultScreen(
    String barcode,
    double price,
    String productName,
    String categoryId, {
    int quantity = 1,
    double? unitPrice,
  }) {
    if (_hourlyRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up your profile first!')),
      );
      return;
    }

    final hoursNeeded = price / _hourlyRate;
    final hours = hoursNeeded.floor();
    final minutes = ((hoursNeeded - hours) * 60).round();
    final displayName = productName.isEmpty ? 'Unknown Product' : productName;
    final cat = kCategories.firstWhere((c) => c['id'] == categoryId);
    final workDays = hoursNeeded / _dailyHours;
    final showWorkDays = workDays >= 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2E45),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<String>(
          future: _getAwarenessMessage(categoryId),
          builder: (context, snapshot) {
            final message = snapshot.data ?? '';
            return SingleChildScrollView(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (cat['color'] as Color).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cat['icon'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            color: cat['color'] as Color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (quantity > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'x$quantity',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This product costs you',
                    style: TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${hours}h ${minutes}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  if (showWorkDays)
                    Text(
                      'approx. ${workDays.toStringAsFixed(1)} work days',
                      style: TextStyle(
                        color: cat['color'] as Color,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const Text(
                    'of your life',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  if (message.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (cat['color'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text(
                                quantity > 1 ? 'Total Price' : 'Price',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_currency${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (quantity > 1 && unitPrice != null)
                                Text(
                                  '$_currency${unitPrice.toStringAsFixed(2)} x $quantity',
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Your rate',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_currency${_hourlyRate.toStringAsFixed(2)}/hr',
                                style: const TextStyle(
                                  color: Colors.white,
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
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(
                              height: 52,
                              child: Center(
                                child: Text(
                                  'SCAN AGAIN',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await _saveToHistory(
                                displayName,
                                price,
                                hours,
                                minutes,
                                categoryId,
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              }
                            },
                            child: const SizedBox(
                              height: 52,
                              child: Center(
                                child: Text(
                                  'DONE',
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Container(
                color: const Color(0xFF0D1B2A),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📷', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 20),
                        const Text(
                          'Camera Access Required',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Please allow camera access in your\ndevice settings to scan barcodes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0D1B2A),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Scan Barcode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _controller.toggleTorch(),
                    icon: const Icon(
                      Icons.flashlight_on_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'Point at a barcode',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Align barcode within the frame',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
