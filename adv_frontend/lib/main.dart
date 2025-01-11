import 'package:flutter/material.dart';
import 'dart:async';
import 'pages/backstory_page.dart';
import 'pages/choice_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated during setup
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class Routes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String backstory = '/backstory';
  static const String choice = '/choice';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAuth.instance.signInAnonymously();
  String userId = FirebaseAuth.instance.currentUser!.uid;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  DocumentReference userDoc = firestore.collection('user').doc(userId);
  DocumentSnapshot docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    await userDoc.set({
      'created_at': FieldValue.serverTimestamp(),
      'latest_at': FieldValue.serverTimestamp(),
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unfoldy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7069A1)),
        useMaterial3: true,
        fontFamily: 'Poppins', // or Nunito, Lato
        scaffoldBackgroundColor: Colors.white, // base
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.home: (context) => const HomeScreen(),
        Routes.backstory: (context) => const BackstoryPage(),
        Routes.choice: (context) => const ChoicePage(
              story: '',
              choices: [],
              sessionId: '',
              imageFiles: [],
            ),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _imageController;
  late AnimationController _titleController;
  late AnimationController _subtitleController;
  late Animation<double> _imageOpacity;
  late Animation<double> _titleOpacity;
  late Animation<double> _subtitleWidth;
  late Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

    _imageController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _imageOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(_imageController);

    _titleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _titleOpacity =
        Tween<double>(begin: 0.0, end: 1.0).animate(_titleController);

    _subtitleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _subtitleWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeInOut),
    );
    _loadingOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _subtitleController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await _imageController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _subtitleController.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(Routes.home);
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          FadeTransition(
            opacity: _imageOpacity,
            child: Image.asset(
              'assets/splash.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          // Title "UNFOLDY"
          FadeTransition(
            opacity: _titleOpacity,
            child: Align(
              alignment: const Alignment(0, -0.33), // 1/3 from top
              child: Text(
                'UNFOLDY',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7069A1), // Updated color
                ),
              ),
            ),
          ),
          // Animated Subtitle and Loading
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  height:
                      MediaQuery.of(context).size.height * 0.33), // 1/3 down
              AnimatedBuilder(
                animation: _subtitleWidth,
                builder: (context, child) {
                  return ClipRect(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width *
                          _subtitleWidth.value,
                      child: Text(
                        'Stories Unfold with You',
                        style: GoogleFonts.italianno(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24), // Margin
              FadeTransition(
                opacity: _loadingOpacity,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF7069A1)),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackstoryPage()),
            );
          },
          child: const Text('Start'),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double kHorizontalPadding = 32.0;
  static const double kButtonHeight = 56.0;
  static const double kBottomPadding = 48.0;
  static const Color kPrimaryColor = Color(0xFF7069A1);
  static const Color kButtonTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/main_screen.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App Title
                Padding(
                  padding: const EdgeInsets.only(top: 48.0),
                  child: Text(
                    'UNFOLDY',
                    style: GoogleFonts.poppins(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7069A1),
                    ),
                  ),
                ),

                // Tagline
                Text(
                  'Stories Unfold with You',
                  style: GoogleFonts.italianno(
                    fontSize: 32,
                    color: Colors.black87,
                  ),
                ),

                const Spacer(),

                // Bottom Button
                Padding(
                  padding: const EdgeInsets.only(
                    left: kHorizontalPadding,
                    right: kHorizontalPadding,
                    bottom: kBottomPadding,
                  ),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.backstory),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kButtonTextColor,
                      minimumSize: const Size(double.infinity, kButtonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0, // Remove elevation
                    ),
                    child: Text(
                      'UNFOLD YOUR STORY',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6E0FF), Color(0xFFFFD6E8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
