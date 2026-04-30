import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pin_session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '';
  bool _busy = false;

  Future<void> _submitIfReady() async {
    if (_pin.length != kPinLength || _busy) return;
    setState(() => _busy = true);
    final ok =
        await context.read<PinSessionProvider>().verifyAndUnlock(_pin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onDigit(String d) {
    if (_busy || _pin.length >= kPinLength) return;
    setState(() => _pin += d);
    if (_pin.length == kPinLength) {
      _submitIfReady();
    }
  }

  void _onBackspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Icon(Icons.lock_outline_rounded,
                  size: 48, color: AppColors.brand.withValues(alpha: 0.9)),
              const SizedBox(height: 20),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your PIN to continue',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 36),
              PinDots(filled: _pin.length),
              const SizedBox(height: 28),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
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
