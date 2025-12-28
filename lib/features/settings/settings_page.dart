import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kitaid1/features/services/biometric_auth_service.dart';
import 'package:kitaid1/features/settings/contact_page.dart';
import 'package:kitaid1/features/settings/privacy_policy_page.dart';
import 'package:kitaid1/features/support/faq_page.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

enum AppLanguage { bm, en }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppLanguage _lang = AppLanguage.en;

  // ✅ Biometric state
  bool _bioSupported = false;
  bool _bioEnabled = false;
  bool _bioLoading = false;

  // ✅ NEW: detect Face availability for UI label/icon
  bool _bioIsFace = false;

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final bio = BiometricAuthService.instance;

    final supported = await bio.isDeviceSupported();
    final enabled = await bio.isEnabled();

    // Face detection only matters when supported
    final isFace = supported ? await bio.supportsFace() : false;

    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
      _bioIsFace = isFace;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_bioLoading) return;

    final bio = BiometricAuthService.instance;

    setState(() => _bioLoading = true);

    // Re-check support at toggle time
    final supported = await bio.isDeviceSupported();
    if (!supported) {
      if (!mounted) return;
      setState(() => _bioLoading = false);
      _snack('Biometric is not supported on this device.');
      return;
    }

    // If turning ON -> verify once
    if (value) {
      final enrolled = await bio.hasEnrolledBiometrics();
      if (!enrolled) {
        if (!mounted) return;
        setState(() => _bioLoading = false);
        _snack('No fingerprint/Face ID enrolled. Please add it in phone settings.');
        return;
      }

      final ok = await bio.authenticate(
        reason: _bioIsFace ? 'Enable Face ID login for KitaID' : 'Enable biometric login for KitaID',
      );

      if (!ok) {
        if (!mounted) return;
        setState(() => _bioLoading = false);
        _snack('Biometric verification failed.');
        return;
      }
    }

    await bio.setEnabled(value);

    // Refresh face availability for correct icon/label
    final isFace = await bio.supportsFace();

    if (!mounted) return;
    setState(() {
      _bioEnabled = value;
      _bioIsFace = isFace;
      _bioLoading = false;
    });

    _snack(value ? 'Biometric login enabled' : 'Biometric login disabled');
  }

  String t(String key) {
    final bm = _lang == AppLanguage.bm;
    switch (key) {
      case 'title':
        return bm ? 'Tetapan' : 'Settings';
      case 'language':
        return bm ? 'Bahasa' : 'Language';
      case 'bm':
        return 'BM';
      case 'en':
        return 'EN';
      case 'account':
        return bm ? 'Akaun' : 'Account';
      case 'about':
        return bm ? 'Mengenai' : 'About';
      case 'change_password':
        return bm ? 'Tukar Kata Laluan' : 'Change Password';
      case 'delete_account':
        return bm ? 'Padam Akaun' : 'Delete Account';
      case 'faq':
        return bm ? 'Soalan Lazim' : 'FAQ';
      case 'privacy':
        return bm ? 'Dasar Privasi' : 'Privacy Policy';
      case 'contact':
        return bm ? 'Kenalan' : 'Contact';
      case 'sign_out':
        return bm ? 'Log keluar' : 'Sign Out';

      // ✅ NEW strings
      case 'face_login':
        return bm ? 'Log Masuk Face ID' : 'Face ID Login';
      case 'bio_login':
        return bm ? 'Log Masuk Biometrik' : 'Biometric Login';
      case 'face_desc':
        return bm ? 'Guna Face ID untuk log masuk' : 'Use Face ID to login';
      case 'bio_desc':
        return bm
            ? 'Guna cap jari / Face ID untuk log masuk'
            : 'Use fingerprint / Face ID to login';

      default:
        return key;
    }
  }

  void _onChangeLanguage(AppLanguage lang) {
    setState(() => _lang = lang);
  }

  Future<void> _signOut() async {
    try {
      // Optional: Disable biometric flag on sign out (your choice)
      await BiometricAuthService.instance.setEnabled(false);

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _snack('Sign out failed: $e');
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Are you sure?",
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontSize: mysizes.fontMd,
                ),
          ),
          content: Text(
            "Do you really want to sign out?",
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  fontSize: mysizes.fontSm,
                  fontWeight: FontWeight.w500,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "No",
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _signOut();
              },
              child: const Text(
                "Yes",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = _bioIsFace ? t('face_login') : t('bio_login');
    final subtitle = _bioIsFace ? t('face_desc') : t('bio_desc');
    final icon = _bioIsFace ? Icons.face : Icons.fingerprint;

    return Scaffold(
      backgroundColor: mycolors.bgPrimary,
      appBar: AppBar(
        title: Text(
          t('title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: mycolors.Primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _SettingsTileContainer(
            child: _LanguageRow(
              icon: Icons.language,
              label: t('language'),
              lang: _lang,
              onChanged: _onChangeLanguage,
              bmText: t('bm'),
              enText: t('en'),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            t('account'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: mysizes.fontMd,
                  color: mycolors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),

          if (_bioSupported)
            _SettingsSwitchTile(
              icon: icon,
              label: label,
              subtitle: subtitle,
              value: _bioEnabled,
              loading: _bioLoading,
              onChanged: _toggleBiometric,
            ),

          _SettingsTile(
            icon: Icons.lock_outline,
            label: t('change_password'),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: t('delete_account'),
            iconColor: mycolors.warningprinmary,
            labelStyle: TextStyle(
              color: mycolors.warningprinmary,
              fontSize: mysizes.fontSm,
            ),
            onTap: () => Navigator.pushNamed(context, '/delete-account'),
          ),

          const SizedBox(height: 28),

          Text(
            t('about'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: mycolors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: mysizes.fontMd,
                ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.help_outline,
            label: t('faq'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqPage()),
              );
            },
          ),

          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            label: t('privacy'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),

          _SettingsTile(
            icon: Icons.support_agent_outlined,
            label: t('contact'),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ContactPage(),
              );
            },
          ),

          const SizedBox(height: 28),

          _SettingsTile(
            icon: Icons.logout,
            label: t('sign_out'),
            iconColor: mycolors.warningprinmary,
            labelStyle: TextStyle(
              color: mycolors.warningprinmary,
              fontSize: mysizes.fontSm,
            ),
            onTap: _showSignOutDialog,
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.icon,
    required this.label,
    required this.lang,
    required this.onChanged,
    required this.bmText,
    required this.enText,
  });

  final IconData icon;
  final String label;
  final AppLanguage lang;
  final ValueChanged<AppLanguage> onChanged;
  final String bmText;
  final String enText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: mycolors.iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: mycolors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: mysizes.fontSm,
              ),
        ),
        const Spacer(),
        _LangChip(
          text: bmText,
          selected: lang == AppLanguage.bm,
          onTap: () => onChanged(AppLanguage.bm),
        ),
        const SizedBox(width: 8),
        _LangChip(
          text: enText,
          selected: lang == AppLanguage.en,
          onTap: () => onChanged(AppLanguage.en),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? mycolors.Primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? mycolors.Primary
                : mycolors.textPrimary.withOpacity(0.15),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : mycolors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsTileContainer extends StatelessWidget {
  const _SettingsTileContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mycolors.borderprimary,
        borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
        border: Border.all(color: mycolors.borderprimary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.labelStyle,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: mycolors.borderprimary,
        borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
        border: Border.all(color: mycolors.borderprimary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: iconColor ?? mycolors.iconColor),
        title: Text(
          label,
          style: labelStyle ??
              Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                    fontSize: mysizes.fontSm,
                  ),
        ),
        trailing: Icon(Icons.chevron_right, color: mycolors.iconColor),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool loading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: mycolors.borderprimary,
        borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
        border: Border.all(color: mycolors.borderprimary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: mycolors.iconColor),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mycolors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: mysizes.fontSm,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mycolors.textPrimary.withOpacity(0.75),
                fontWeight: FontWeight.w600,
                fontSize: mysizes.fontSm,
              ),
        ),
        trailing: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: value,
                onChanged: onChanged,
              ),
      ),
    );
  }
}
