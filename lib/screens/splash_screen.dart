import 'package:deviceguardianadmin/providers/home_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/util/app_constants.dart';
import 'package:deviceguardianadmin/util/session_manager.dart';
import 'package:deviceguardianadmin/util/styles.dart';
import 'package:deviceguardianadmin/widgets/app_update_dialog.dart';
import 'package:deviceguardianadmin/widgets/guardian_loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import '../util/post_login_navigation.dart';

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
    if (!mounted) return;

    final loginProvider = context.read<LoginProvider>();
    final homeProvider = context.read<HomeProvider>();

    // Check app version for all users (logged in or not) before navigation
    final isOutdated = await homeProvider.getAppVersion();
    if (!mounted) return;

    if (isOutdated) {
      showAppUpdateDialog(
        context,
        downloadUrl: homeProvider.downloadUrl,
        currentVersion: homeProvider.installedAppVersion,
        newVersion: homeProvider.latestServerVersion,
      );
      return;
    }

    if (!await loginProvider.checkLoginStatus()) {
      _navigateToLogin();
      return;
    }

    if (!mounted || !await SessionManager.isSessionActive()) {
      return;
    }

    if (!mounted) return;
    await PostLoginNavigation.navigate(context);
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
                      width: 300,
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