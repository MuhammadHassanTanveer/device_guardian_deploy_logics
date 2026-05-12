import 'package:deviceguardianadmin/providers/home_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/guardian_loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'update_pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final provider = context.read<LoginProvider>();
      final isLoggedIn = await provider.checkLoginStatus();

      if (mounted) {
        if (!isLoggedIn) {
          // Not logged in, go to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        } else {
          // Already logged in, pre-fetch app version for the home screen
          // This ensures version check happens early
          await context.read<HomeProvider>().getAppVersion();
          
          // Check for PIN code
          final pinCode = await provider.getPinCode();
          
          if (!mounted) return;
          
          if (pinCode == null) {
            // API call failed, check stored PIN
            final storedPin = await provider.getStoredPinCode();
            if (storedPin != null && storedPin.isNotEmpty) {
              // Has stored PIN, go to home
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else {
              // No stored PIN and API failed, force PIN setup
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const UpdatePinScreen(isFirstTime: true)),
                (route) => false,
              );
            }
          } else if (pinCode.isEmpty) {
            // Pin code is not set, show update pin screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const UpdatePinScreen(isFirstTime: true)),
              (route) => false,
            );
          } else {
            // Pin code exists, navigate to home screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        height: MediaQuery.sizeOf(context).height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface, // Alice blue background (F0F8FF)
              colorScheme.tertiaryContainer, // Lighter sky blue (A8C6FF)
            ],
          ),
        ),
        child: Column(
          children: [
            // Main content centered
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo
                    Image.asset(
                      'assets/images/logo.png',
                      // height: 120,
                    ),
                    const SizedBox(height: 20),
                    Text("Device Guardian Admin", style: robotoBold(context).copyWith(fontSize: 22),),
                    const SizedBox(height: 30),
                    const GuardianLoadingAnimation(size: 100),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  Text("Version: ${AppConstants.appVersion}", style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor), ),
                  const SizedBox(height: 5),
                  Text("Powered by Deploy Logics", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontStyle: FontStyle.italic), ),
                  Text("deploylogics.com", style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontStyle: FontStyle.italic), ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}