import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const reverieLaunchBackground = Color(0xFFF7F7F8);
const reverieLaunchTitleColor = Color(0xFF1C1C22);
const reverieLaunchSubtitleColor = Color(0xFF70707A);

class ReverieLaunchApp extends StatelessWidget {
  const ReverieLaunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReverieLaunchScreen(),
    );
  }
}

class ReverieLaunchScreen extends StatelessWidget {
  const ReverieLaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: reverieLaunchBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: reverieLaunchBackground,
        body: Center(child: _ReverieLaunchLockup()),
      ),
    );
  }
}

class _ReverieLaunchLockup extends StatelessWidget {
  const _ReverieLaunchLockup();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reverie 正在启动',
      child: SizedBox(
        width: 280,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -50),
              child: Image.asset(
                'assets/branding/launch_mark.png',
                width: 144,
                height: 144,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 28),
              child: const Text(
                'Reverie',
                style: TextStyle(
                  color: reverieLaunchTitleColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 58),
              child: const Text(
                '听自己的音乐',
                style: TextStyle(
                  color: reverieLaunchSubtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
