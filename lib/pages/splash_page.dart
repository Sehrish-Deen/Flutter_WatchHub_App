import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/auth_gate.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  late AnimationController _arrowController;
  late Animation<Offset> _arrowAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    // Arrow animation
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _goToNext() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < 0) {
            _goToNext();
          }
        },
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/splashscreen.jpg",
                fit: BoxFit.cover,
              ),
            ),

            // Dark Overlay
            Container(
              color: Colors.black54,
            ),

            // Center Content
            FadeTransition(
              opacity: _fadeIn,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        "WATCH HUB",
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Your Style • Your Time",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.orange,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Arrow
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _arrowAnimation,
                child: GestureDetector(
                  onTap: _goToNext,
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.orange,
                    size: 42,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}