import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.explore,
      'color': Colors.blue,
      'title': 'Descubre tu ciudad',
      'subtitle': 'Encuentra los mejores lugares cerca de ti',
    },
    {
      'icon': Icons.star,
      'color': Colors.amber,
      'title': 'Lee y comparte reseñas',
      'subtitle': 'Conoce la opinión de otros usuarios antes de visitar',
    },
    {
      'icon': Icons.favorite,
      'color': Colors.red,
      'title': 'Guarda tus favoritos',
      'subtitle': 'Accede rápidamente a los lugares que más te gustan',
    },
  ];

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemCount: _pages.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_pages[i]['icon'], size: 120, color: _pages[i]['color']),
                    const SizedBox(height: 40),
                    Text(_pages[i]['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text(_pages[i]['subtitle'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _finish();
                        } else {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_currentPage == _pages.length - 1 ? "Comenzar" : "Siguiente"),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
