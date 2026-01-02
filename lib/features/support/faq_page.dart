import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mycolors.Primary, 
        foregroundColor: Colors.white, 
        elevation: 0,
        title: const Text(
          'FAQ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // Header
                Text(
                  'Frequently Asked Questions (FAQ)',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: mycolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: June 03, 2025',
                  style: textTheme.bodyMedium?.copyWith(
                    color: mycolors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Intro block
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _P(
                        textTheme,
                        'This page answers some common questions about using KitaID. '
                        'If you can’t find what you’re looking for, please reach out to us using the contact details at the bottom of this page.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── GETTING STARTED ─────
                _H2(textTheme, 'Getting Started'),
                const SizedBox(height: 8),
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _H3(textTheme, 'What is KitaID?'),
                      _P(
                        textTheme,
                        'KitaID is a digital identity wallet designed for users in Malaysia. '
                        'It helps you securely store and access your important identity documents '
                        '(such as MyKad, passport, and driver’s license) in one place, with biometric login '
                        'and QR-based verification.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'How do I create an account?'),
                      _P(
                        textTheme,
                        'You can create an account directly in the app by registering with your phone number '
                        'and basic details. After signing up, you’ll verify your account using a one-time '
                        'password (OTP) sent to your phone.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'Which documents can I add to KitaID?'),
                      _P(
                        textTheme,
                        'In our current version, KitaID focuses on the following document types:',
                      ),
                      _BulletList(textTheme, const [
                        'MyKad / I-Kad information',
                        'Passport information',
                        'Driver’s license information',
                        'Other supporting identity-related documents (where supported)',
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── ACCOUNTS & LOGIN ─────
                _H2(textTheme, 'Accounts & Login'),
                const SizedBox(height: 8),
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _H3(textTheme, 'What login methods are supported?'),
                      _P(
                        textTheme,
                        'KitaID supports secure login using your registered phone number and password. '
                        'If your device supports it, you can also enable biometric login (fingerprint or '
                        'face ID) from the Settings page for faster access.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'I forgot my password. What should I do?'),
                      _P(
                        textTheme,
                        'On the login screen, tap “Forgot Password”. Follow the instructions to verify '
                        'your phone number and set a new password.',
                      ),
                      const _FaqDivider(),

                      _H3(
                          textTheme, 'Can I use my account on multiple devices?'),
                      _P(
                        textTheme,
                        'You can log in to KitaID on another device using your registered account. '
                        'For security reasons, you may be asked to re-verify your identity '
                        '(for example, via OTP or security checks) when using a new device.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── SECURITY & PRIVACY ─────────
                _H2(textTheme, 'Security & Privacy'),
                const SizedBox(height: 8),
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _H3(textTheme, 'Is my data safe in KitaID?'),
                      _P(
                        textTheme,
                        'We take security seriously. KitaID uses secure communication and storage practices '
                        'to help protect your data. Biometric login, encrypted storage, and secure sessions '
                        'are used to reduce the risk of unauthorized access.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'Can anyone else see my documents?'),
                      _P(
                        textTheme,
                        'Your documents are only visible when you unlock the app using your password or '
                        'biometrics. When you choose to share or display a QR code for verification, only '
                        'the necessary information is shown to the verifier.',
                      ),
                      const _FaqDivider(),

                      _H3(
                        textTheme,
                        'Does KitaID share my data with third parties?',
                      ),
                      _P(
                        textTheme,
                        'We do not sell your personal data. Any data sharing (for example, with service '
                        'providers or verification partners) is done only to provide core features of KitaID '
                        'and according to our privacy practices.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── USING YOUR DIGITAL IDS ──────
                _H2(textTheme, 'Using Your Digital IDs'),
                const SizedBox(height: 8),
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _H3(textTheme, 'How does QR verification work?'),
                      _P(
                        textTheme,
                        'Certain services can scan your KitaID QR code to quickly confirm your identity '
                        'details. The QR contains a secure reference to your data, and only authorized '
                        'verifiers can read the necessary information.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'Can I use KitaID offline?'),
                      _P(
                        textTheme,
                        'Some features, such as viewing previously stored documents, may work offline. '
                        'However, actions that require real-time verification or syncing (like updating data, '
                        'OTP, or online checks) will need an internet connection.',
                      ),
                      const _FaqDivider(),

                      _H3(
                          textTheme, 'Is KitaID an official government app?'),
                      _P(
                        textTheme,
                        'KitaID is a student project / prototype application designed to demonstrate a modern '
                        'digital identity experience. It is not an official replacement for any government-'
                        'issued ID, and users should always follow official guidelines for legal identification.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── TROUBLESHOOTING & SUPPORT ─────────
                _H2(textTheme, 'Troubleshooting & Support'),
                const SizedBox(height: 8),
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _H3(textTheme,
                          'The app is not loading / keeps crashing. What can I do?'),
                      _P(
                        textTheme,
                        'Try the following steps:',
                      ),
                      _BulletList(textTheme, const [
                        'Close and reopen the app.',
                        'Ensure you have a stable internet connection.',
                        'Update the app to the latest version (if available).',
                        'Restart your device and try again.',
                      ]),
                      const _FaqDivider(),

                      _H3(textTheme, 'My information is not updating.'),
                      _P(
                        textTheme,
                        'First, check your internet connection. Then log out and log back in to refresh '
                        'your session. If the issue continues, contact us with details and screenshots so '
                        'we can investigate further.',
                      ),
                      const _FaqDivider(),

                      _H3(textTheme, 'How can I contact the KitaID team?'),
                      _P(
                        textTheme,
                        'If you have any questions, feedback, or want to report an issue, you can contact '
                        'us via email:',
                      ),
                      _P(
                        textTheme,
                        'Email: monirsa2002@gmail.com',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Helper Widgets ----------

class _CardBlock extends StatelessWidget {
  const _CardBlock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
        border: Border.all(
          color: mycolors.borderprimary.withValues(alpha: 140),
        ),
      ),
      child: child,
    );
  }
}

class _FaqDivider extends StatelessWidget {
  const _FaqDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: mycolors.borderprimary.withOpacity(0.8),
      ),
    );
  }
}

Widget _H2(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700,fontSize: mysizes.fontMd),
      ),
    );

Widget _H3(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700,fontSize: mysizes.fontMd),
      ),
    );

Widget _P(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: t.bodyMedium?.copyWith(
        fontSize: mysizes.fontSm,
      ), 
      textAlign: TextAlign.left),
    );

class _BulletList extends StatelessWidget {
  const _BulletList(this.textTheme, this.items);
  final TextTheme textTheme;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        e,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: mysizes.fontSm,
                        )
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
