import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pin_session_provider.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

enum _PinChangeStep { enterOld, enterNew, confirmNew }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  _PinChangeStep _step = _PinChangeStep.enterOld;
  String _pin = '';
  String _newFirst = '';
  String _oldVerified = '';

  String get _title {
    switch (_step) {
      case _PinChangeStep.enterOld:
        return 'Current PIN';
      case _PinChangeStep.enterNew:
        return 'New PIN';
      case _PinChangeStep.confirmNew:
        return 'Confirm new PIN';
    }
  }

  String get _subtitle {
    switch (_step) {
      case _PinChangeStep.enterOld:
        return 'Enter your current 6-digit PIN';
      case _PinChangeStep.enterNew:
        return 'Choose a new 6-digit PIN';
      case _PinChangeStep.confirmNew:
        return 'Enter the new PIN again';
    }
  }

  Future<void> _handleFullPin() async {
    if (_pin.length != kPinLength) return;

    switch (_step) {
      case _PinChangeStep.enterOld:
        final ok = await SecurityService.instance.verifyPin(_pin);
        if (!mounted) return;
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect PIN'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _pin = '');
          return;
        }
        _oldVerified = _pin;
        setState(() {
          _pin = '';
          _step = _PinChangeStep.enterNew;
        });
        return;

      case _PinChangeStep.enterNew:
        _newFirst = _pin;
        setState(() {
          _pin = '';
          _step = _PinChangeStep.confirmNew;
        });
        return;

      case _PinChangeStep.confirmNew:
        if (_pin != _newFirst) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New PINs did not match. Try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {
            _step = _PinChangeStep.enterNew;
            _pin = '';
            _newFirst = '';
          });
          return;
        }
        final changed = await context
            .read<PinSessionProvider>()
            .changePin(_oldVerified, _pin);
        if (!mounted) return;
        if (changed) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('PIN updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
    }
  }

  void _onDigit(String d) {
    if (_pin.length >= kPinLength) return;
    setState(() => _pin += d);
    if (_pin.length == kPinLength) {
      _handleFullPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Change PIN'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 28),
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
