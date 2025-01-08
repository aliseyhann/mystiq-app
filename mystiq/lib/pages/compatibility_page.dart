import 'package:flutter/material.dart';

class CompatibilityPage extends StatefulWidget {
  const CompatibilityPage({super.key});

  @override
  State<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage> {
  final List<Map<String, dynamic>> zodiacSigns = [
    {
      'name': 'Aries',
      'element': 'Fire',
      'quality': 'Cardinal',
      'ruler': 'Mars',
      'image': 'assets/zodiac/aries.png'
    },
    {
      'name': 'Taurus',
      'element': 'Earth',
      'quality': 'Fixed',
      'ruler': 'Venus',
      'image': 'assets/zodiac/taurus.png'
    },
    {
      'name': 'Gemini',
      'element': 'Air',
      'quality': 'Mutable',
      'ruler': 'Mercury',
      'image': 'assets/zodiac/gemini.png'
    },
    {
      'name': 'Cancer',
      'element': 'Water',
      'quality': 'Cardinal',
      'ruler': 'Moon',
      'image': 'assets/zodiac/cancer.png'
    },
    {
      'name': 'Leo',
      'element': 'Fire',
      'quality': 'Fixed',
      'ruler': 'Sun',
      'image': 'assets/zodiac/leo.png'
    },
    {
      'name': 'Virgo',
      'element': 'Earth',
      'quality': 'Mutable',
      'ruler': 'Mercury',
      'image': 'assets/zodiac/virgo.png'
    },
    {
      'name': 'Libra',
      'element': 'Air',
      'quality': 'Cardinal',
      'ruler': 'Venus',
      'image': 'assets/zodiac/libra.png'
    },
    {
      'name': 'Scorpio',
      'element': 'Water',
      'quality': 'Fixed',
      'ruler': 'Mars/Pluto',
      'image': 'assets/zodiac/scorpio.png'
    },
    {
      'name': 'Sagittarius',
      'element': 'Fire',
      'quality': 'Mutable',
      'ruler': 'Jupiter',
      'image': 'assets/zodiac/sagittarius.png'
    },
    {
      'name': 'Capricorn',
      'element': 'Earth',
      'quality': 'Cardinal',
      'ruler': 'Saturn',
      'image': 'assets/zodiac/capricorn.png'
    },
    {
      'name': 'Aquarius',
      'element': 'Air',
      'quality': 'Fixed',
      'ruler': 'Saturn/Uranus',
      'image': 'assets/zodiac/aquarius.png'
    },
    {
      'name': 'Pisces',
      'element': 'Water',
      'quality': 'Mutable',
      'ruler': 'Jupiter/Neptune',
      'image': 'assets/zodiac/pisces.png'
    },
  ];

  int selectedIndex1 = 0;
  int selectedIndex2 = 0;
  final TextEditingController name1Controller = TextEditingController();
  final TextEditingController name2Controller = TextEditingController();
  int? compatibilityScore;
  String? compatibilityMessage;

  int calculateCompatibility() {
    if (name1Controller.text.isEmpty || name2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen isimleri girin')),
      );
      return 0;
    }

    final sign1 = zodiacSigns[selectedIndex1];
    final sign2 = zodiacSigns[selectedIndex2];
    
    int score = 0;
    
    // İsim Uyumu (0-20 puan)
    final nameScore = calculateNameCompatibility(
      name1Controller.text.trim(),
      name2Controller.text.trim()
    );
    score += nameScore;

    // Element Uyumu (0-25 puan)
    if (sign1['element'] == sign2['element']) {
      score += 25; // Aynı element mükemmel uyum
    } else {
      switch (sign1['element']) {
        case 'Fire':
          if (sign2['element'] == 'Air') score += 20;
          else if (sign2['element'] == 'Earth') score += 12;
          else if (sign2['element'] == 'Water') score += 8;
          break;
        case 'Earth':
          if (sign2['element'] == 'Water') score += 20;
          else if (sign2['element'] == 'Fire') score += 12;
          else if (sign2['element'] == 'Air') score += 8;
          break;
        case 'Air':
          if (sign2['element'] == 'Fire') score += 20;
          else if (sign2['element'] == 'Water') score += 12;
          else if (sign2['element'] == 'Earth') score += 8;
          break;
        case 'Water':
          if (sign2['element'] == 'Earth') score += 20;
          else if (sign2['element'] == 'Air') score += 12;
          else if (sign2['element'] == 'Fire') score += 8;
          break;
      }
    }

    // Nitelik Uyumu (0-25 puan)
    if (sign1['quality'] == sign2['quality']) {
      score += 15; // Aynı nitelik iyi uyum
    } else {
      if ((sign1['quality'] == 'Cardinal' && sign2['quality'] == 'Fixed') ||
          (sign1['quality'] == 'Fixed' && sign2['quality'] == 'Cardinal')) {
        score += 25; // Cardinal-Fixed en iyi uyum
      } else if ((sign1['quality'] == 'Mutable' && sign2['quality'] == 'Fixed') ||
                 (sign1['quality'] == 'Fixed' && sign2['quality'] == 'Mutable')) {
        score += 15;
      } else {
        score += 10; // Diğer kombinasyonlar
      }
    }

    // Gezegen Uyumu (0-30 puan)
    if (sign1['ruler'] == sign2['ruler']) {
      score += 25; // Aynı yönetici gezegen
    } else {
      // Olumlu Gezegen Kombinasyonları
      final rulers1 = sign1['ruler'].split('/');
      final rulers2 = sign2['ruler'].split('/');
      
      for (var ruler1 in rulers1) {
        for (var ruler2 in rulers2) {
          if ((ruler1 == 'Venus' && ruler2 == 'Mars') ||
              (ruler1 == 'Mars' && ruler2 == 'Venus') ||
              (ruler1 == 'Sun' && ruler2 == 'Moon') ||
              (ruler1 == 'Moon' && ruler2 == 'Sun') ||
              (ruler1 == 'Jupiter' && ruler2 == 'Mercury') ||
              (ruler1 == 'Mercury' && ruler2 == 'Jupiter')) {
            score += 30;
            break;
          }
        }
      }
    }

    // Mesaj belirleme
    setState(() {
      if (score >= 85) {
        compatibilityMessage = 'Perfect match! This relationship could be very special.';
      } else if (score >= 70) {
        compatibilityMessage = 'Great compatibility. You complement each other well.';
      } else if (score >= 50) {
        compatibilityMessage = 'Moderate compatibility. Worth putting in the effort.';
      } else {
        compatibilityMessage = 'Challenging compatibility. May require patience and understanding.';
      }
    });

    return score;
  }

  int calculateNameCompatibility(String name1, String name2) {
    // İsimleri küçük harfe çevirip Türkçe karakterleri düzeltiyoruz
    name1 = _normalizeText(name1.toLowerCase());
    name2 = _normalizeText(name2.toLowerCase());

    int score = 0;

    // 1. Sesli Harf Uyumu (0-7 puan)
    final vowels1 = _getVowels(name1);
    final vowels2 = _getVowels(name2);
    
    if (vowels1.length == vowels2.length) score += 3;
    
    // Kalın-ince sesli harf uyumu
    final thickVowels1 = vowels1.where((v) => 'aıou'.contains(v)).length;
    final thickVowels2 = vowels2.where((v) => 'aıou'.contains(v)).length;
    if ((thickVowels1 > vowels1.length / 2 && thickVowels2 > vowels2.length / 2) ||
        (thickVowels1 < vowels1.length / 2 && thickVowels2 < vowels2.length / 2)) {
      score += 4;
    }

    // 2. Harf Sayısı Uyumu (0-3 puan)
    if (name1.length == name2.length) {
      score += 3;
    } else if ((name1.length - name2.length).abs() <= 2) {
      score += 2;
    }

    // 3. Ortak Harf Uyumu (0-5 puan)
    final commonLetters = name1.split('').toSet().intersection(name2.split('').toSet());
    score += (commonLetters.length * 5 ~/ name1.length).clamp(0, 5);

    // 4. İsim Numerolojisi (0-5 puan)
    final numerology1 = _calculateNumerology(name1);
    final numerology2 = _calculateNumerology(name2);
    
    if (numerology1 == numerology2) {
      score += 5;
    } else if ((numerology1 + numerology2) % 3 == 0) {
      score += 3;
    }

    return score;
  }

  String _normalizeText(String text) {
    const turkishChars = 'çğıöşüâîû';
    const englishChars = 'cgiosua';
    
    String normalized = text;
    for (int i = 0; i < turkishChars.length; i++) {
      normalized = normalized.replaceAll(turkishChars[i], englishChars[i % englishChars.length]);
    }
    return normalized;
  }

  List<String> _getVowels(String text) {
    return text.split('').where((c) => 'aeıioöuü'.contains(c)).toList();
  }

  int _calculateNumerology(String text) {
    // Her harfe bir sayı değeri atayarak numerolojik toplam hesaplama
    const values = {
      'a': 1, 'b': 2, 'c': 3, 'd': 4, 'e': 5, 'f': 6, 'g': 7, 'h': 8, 'i': 9,
      'j': 1, 'k': 2, 'l': 3, 'm': 4, 'n': 5, 'o': 6, 'p': 7, 'q': 8, 'r': 9,
      's': 1, 't': 2, 'u': 3, 'v': 4, 'w': 5, 'x': 6, 'y': 7, 'z': 8
    };
    
    int total = 0;
    for (var char in text.split('')) {
      total += values[char] ?? 0;
    }
    
    // Toplam tek basamaklı olana kadar basamakları topla
    while (total > 9) {
      total = total.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    
    return total;
  }

  Widget _buildZodiacCard(Map<String, dynamic> sign) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        width: 120,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              sign['image'],
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 8),
            Text(
              sign['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sign['element'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zodiac Compatibility'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: name1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Name of Person 1',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: zodiacSigns.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex1 = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                border: selectedIndex1 == index
                                    ? Border.all(color: Colors.purple, width: 2)
                                    : null,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: _buildZodiacCard(zodiacSigns[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: name2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Name of Person 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: zodiacSigns.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedIndex2 = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                border: selectedIndex2 == index
                                    ? Border.all(color: Colors.purple, width: 2)
                                    : null,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: _buildZodiacCard(zodiacSigns[index]),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final score = calculateCompatibility();
                setState(() {
                  compatibilityScore = score;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Calculate Compatibility',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            if (compatibilityScore != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${name1Controller.text} and ${name2Controller.text}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${zodiacSigns[selectedIndex1]['name']} and ${zodiacSigns[selectedIndex2]['name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Compatibility: $compatibilityScore%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      if (compatibilityMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          compatibilityMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    name1Controller.dispose();
    name2Controller.dispose();
    super.dispose();
  }
} 