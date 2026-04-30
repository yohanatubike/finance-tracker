import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const int kPinLength = 6;

class PinDots extends StatelessWidget {
  final int filled;
  final int total;

  const PinDots({
    super.key,
    required this.filled,
    this.total = kPinLength,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? AppColors.brand : AppColors.surfaceVariant,
            border: Border.all(
              color: on ? AppColors.brand : AppColors.divider,
              width: on ? 0 : 1,
            ),
          ),
        );
      }),
    );
  }
}

typedef PinPadCallback = void Function(String digit);

/// Numeric keypad for a 6-digit PIN (digits + backspace).
class PinPad extends StatelessWidget {
  final PinPadCallback onDigit;
  final VoidCallback onBackspace;

  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      '⌫',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 24,
          childAspectRatio: 1.35,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final label = keys[index];
          if (label.isEmpty) return const SizedBox.shrink();
          if (label == '⌫') {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBackspace,
                customBorder: const CircleBorder(),
                child: const Icon(Icons.backspace_outlined,
                    color: AppColors.secondaryText, size: 22),
              ),
            );
          }
          return Material(
            color: AppColors.surface,
            elevation: 0,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => onDigit(label),
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
