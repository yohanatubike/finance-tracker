import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pin_session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  int _phase = 0;
  String _pin = '';
  String _first = '';

  void _showMismatch() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PINs did not match. Start again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {
      _pin = '';
      _first = '';
      _phase = 0;
    });
  }

  void _onDigit(String d) {
    if (_pin.length >= kPinLength) return;
    setState(() => _pin += d);
    if (_pin.length < kPinLength) return;

    if (_phase == 0) {
      _first = _pin;
      setState(() {
        _pin = '';
        _phase = 1;
      });
      return;
    }

    if (_pin == _first) {
      context.read<PinSessionProvider>().completeSetup(_pin);
    } else {
      _showMismatch();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        _phase == 0 ? 'Choose a 6-digit PIN' : 'Enter the same PIN again';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Icon(Icons.pin_rounded,
                  size: 48, color: AppColors.brand.withValues(alpha: 0.9)),
              const SizedBox(height: 20),
              Text(
                'Secure your app',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 36),
              PinDots(filled: _pin.length),
              const SizedBox(height: 28),
              Expanded(
                child: PinPad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
