import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pin_session_provider.dart';
import '../theme/app_theme.dart';
import 'main_navigation_shell.dart';
import 'pin_setup_screen.dart';
import 'pin_unlock_screen.dart';

/// Locks when the app goes to background ([AppLifecycleState.paused]) so reopening
/// requires the PIN again if the process stayed alive (e.g. home button).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return _LockWhenBackgrounded(
      child: Consumer<PinSessionProvider>(
        builder: (context, pin, _) {
          if (pin.loading) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (pin.needsSetup) return const PinSetupScreen();
          if (!pin.isUnlocked) return const PinUnlockScreen();
          return const MainNavigation();
        },
      ),
    );
  }
}

class _LockWhenBackgrounded extends StatefulWidget {
  final Widget child;

  const _LockWhenBackgrounded({required this.child});

  @override
  State<_LockWhenBackgrounded> createState() => _LockWhenBackgroundedState();
}

class _LockWhenBackgroundedState extends State<_LockWhenBackgrounded>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<PinSessionProvider>().lock();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
