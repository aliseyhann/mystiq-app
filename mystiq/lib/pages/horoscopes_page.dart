import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HoroscopePage extends StatefulWidget {
  @override
  _HoroscopePageState createState() => _HoroscopePageState();
}

class _HoroscopePageState extends State<HoroscopePage> {
  Future<Map<String, dynamic>> _getHoroscopeReading(String sign) async {
    try {
      print('Calling API for sign: $sign');
      final url = Uri.parse('https://horoscope-app-api.vercel.app/api/v1/get-horoscope/daily?sign=${sign.toLowerCase()}&day=today');
      print('API URL: $url');

      final response = await http.get(url);

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['horoscope_data'] != null) {
          return {
            'horoscope': data['data']['horoscope_data'],
            'meta': {
              'mood': 'Positive',
              'keywords': 'Daily Horoscope',
              'intensity': '4/5'
            }
          };
        } else {
          print('API returned null horoscope');
          throw Exception('No horoscope data available');
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load horoscope');
      }
    } catch (e, stackTrace) {
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to load horoscope');
    }
  }

  List<String> horoscopeNames = [
    'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo', 
    'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces'
  ];

  List<String> horoscopeDisplayNames = [
    'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 
    'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
  ];

  List<String> horoscopeImages = [
    'assets/zodiac/aries.png',
    'assets/zodiac/taurus.png',
    'assets/zodiac/gemini.png',
    'assets/zodiac/cancer.png',
    'assets/zodiac/leo.png',
    'assets/zodiac/virgo.png',
    'assets/zodiac/libra.png',
    'assets/zodiac/scorpio.png',
    'assets/zodiac/sagittarius.png',
    'assets/zodiac/capricorn.png',
    'assets/zodiac/aquarius.png',
    'assets/zodiac/pisces.png',
  ];

  List<String> horoscopeElements = [
    'Fire', 'Earth', 'Air', 'Water',
    'Fire', 'Earth', 'Air', 'Water',
    'Fire', 'Earth', 'Air', 'Water'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E1D39),
      appBar: AppBar(
        title: Text(
          "Daily Horoscope",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Choose your zodiac sign and learn your destiny.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap on the signs now to access weekly horoscopes!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _showHoroscopeDialog(context, index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            horoscopeImages[index],
                            width: 60,
                            height: 60,
                            color: Colors.brown.shade900,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 8),
                          Text(
                            horoscopeDisplayNames[index].toUpperCase(),
                            style: TextStyle(
                              color: Colors.brown.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHoroscopeDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getHoroscopeReading(horoscopeNames[index]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.brown.shade900,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Loading horoscope...",
                        style: TextStyle(
                          color: Colors.brown.shade900,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade900,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Failed to load horoscope",
                        style: TextStyle(
                          color: Colors.red.shade900,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final horoscopeData = snapshot.data!;

              return Container(
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            horoscopeImages[index],
                            width: 48,
                            height: 48,
                            color: Colors.brown.shade900,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 16),
                          Text(
                            horoscopeDisplayNames[index].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.brown.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          horoscopeData['horoscope'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.brown.shade900,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.brown.shade900,
                          padding: EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
