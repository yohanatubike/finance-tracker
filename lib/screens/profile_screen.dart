import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';
import 'change_pin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _currencyCtrl;
  late bool _use24HourTime;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<ProfileProvider>(context, listen: false).profile;
    _nameCtrl = TextEditingController(text: p.displayName);
    _emailCtrl = TextEditingController(text: p.email);
    _currencyCtrl = TextEditingController(text: p.currencySymbol.trim());
    _use24HourTime = p.use24HourTime;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    await context.read<ProfileProvider>().save(UserProfile(
          displayName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          currencySymbol:
              _currencyCtrl.text.trim().isEmpty ? 'TZS' : _currencyCtrl.text.trim(),
          use24HourTime: _use24HourTime,
        ));
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer<ProfileProvider>(
                  builder: (context, prof, _) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          _ProfileAvatar(name: prof.profile.displayName),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'This name appears in the menu and greetings.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Display name',
                  hint: 'e.g. Alex (optional)',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email (optional)',
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 22),
                Text(
                  'Regional',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _currencyCtrl,
                  label: 'Currency label',
                  hint: 'TZS',
                  icon: Icons.currency_exchange_rounded,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Shown before amounts across the app (e.g. TZS, USD).',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('24-hour time'),
                  subtitle: Text(
                    'Deadlines and payment times',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  value: _use24HourTime,
                  onChanged: (v) => setState(() => _use24HourTime = v),
                ),
                const SizedBox(height: 28),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.pin_outlined,
                      color: AppColors.brand.withValues(alpha: 0.9)),
                  title: const Text('Change PIN'),
                  subtitle: Text(
                    'Verify your current PIN, then choose a new one',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChangePinScreen(),
                      ),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.divider),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String name;

  const _ProfileAvatar({required this.name});

  String _initials(String raw) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.brandLight,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
