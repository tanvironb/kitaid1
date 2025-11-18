import 'package:flutter/material.dart';
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

  String t(String key) {
    final bm = _lang == AppLanguage.bm;
    switch (key) {
      case 'title': return bm ? 'Tetapan' : 'Settings';
      case 'language': return bm ? 'Bahasa' : 'Language';
      case 'bm': return 'BM';
      case 'en': return 'EN';
      case 'account': return bm ? 'Akaun' : 'Account';
      case 'about': return bm ? 'Mengenai' : 'About';
      case 'change_password': return bm ? 'Tukar Kata Laluan' : 'Change Password';
      case 'delete_account': return bm ? 'Padam Akaun' : 'Delete Account';
      case 'faq': return bm ? 'Soalan Lazim' : 'FAQ';
      case 'privacy': return bm ? 'Dasar Privasi' : 'Privacy Policy';
      case 'contact': return bm ? 'Kenalan' : 'Contact';
      case 'sign_out': return bm ? 'Log keluar' : 'Sign Out';
      default: return key;
    }
  }

  void _onChangeLanguage(AppLanguage lang) {
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) {
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
          // ===== LANGUAGE OPTION (inside container) =====
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

          // ===== ACCOUNT =====
          Text(
            t('account'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: mycolors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.lock_outline,
            label: t('change_password'),
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            label: t('delete_account'),
            iconColor: mycolors.warningprinmary,
            labelStyle: TextStyle(color: mycolors.warningprinmary),
            onTap: () {},
          ),

          const SizedBox(height: 28),

          // ===== ABOUT =====
          Text(
            t('about'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: mycolors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          _SettingsTile(icon: Icons.help_outline, label: t('faq'), onTap: () {}),
          _SettingsTile(icon: Icons.privacy_tip_outlined, label: t('privacy'), onTap: () {}),
          _SettingsTile(icon: Icons.support_agent_outlined, label: t('contact'), onTap: () {}),

          const SizedBox(height: 28),

          _SettingsTile(
            icon: Icons.logout,
            label: t('sign_out'),
            iconColor: mycolors.warningprinmary,
            labelStyle: TextStyle(color: mycolors.warningprinmary),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

//
// ─── LANGUAGE ROW ───────────────────────────────────────────────────────────────
//
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
              ),
        ),
        const Spacer(),
        _LangPill(
          text: bmText,
          selected: lang == AppLanguage.bm,
          onTap: () => onChanged(AppLanguage.bm),
        ),
        const SizedBox(width: 8),
        _LangPill(
          text: enText,
          selected: lang == AppLanguage.en,
          onTap: () => onChanged(AppLanguage.en),
        ),
      ],
    );
  }
}

//
// ─── LANGUAGE PILL STYLE BUTTONS ────────────────────────────────────────────────
//
class _LangPill extends StatelessWidget {
  const _LangPill({
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
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? mycolors.Primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? mycolors.Primary : mycolors.borderprimary,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : mycolors.textPrimary,
          ),
        ),
      ),
    );
  }
}

//
// ─── SETTINGS TILE WRAPPER FOR LANGUAGE ROW ─────────────────────────────────────
//
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

//
// ─── SETTINGS TILE (OTHER OPTIONS) ──────────────────────────────────────────────
//
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
              Theme.of(context).textTheme.bodyMedium?.copyWith(color: mycolors.textPrimary),
        ),
        trailing: Icon(Icons.chevron_right, color: mycolors.iconColor),
        onTap: onTap,
      ),
    );
  }
}
