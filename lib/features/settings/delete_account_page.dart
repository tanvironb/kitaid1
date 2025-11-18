// lib/features/settings/delete_account_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';


class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _acknowledged = false;
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'Are you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      setState(() => _isDeleting = true);

      // TODO: Connect to your backend or Firebase account deletion function.
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );

      // TODO: Redirect to login/onboarding after deletion
      // Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(mysizes.defaultspace),
              children: [
                // ===== Warning Section =====
                Container(
                  padding: const EdgeInsets.all(mysizes.lg),
                  decoration: BoxDecoration(
                    color: mycolors.Primary.withOpacity(0.06),
                    borderRadius:
                        BorderRadius.circular(mysizes.borderRadiusLg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 40, color: error),
                      const SizedBox(width: mysizes.spacebtwitems),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'By deleting your account\npermanently!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: mycolors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: mysizes.sm),
                            Text(
                              'This will remove your account and associated data from KitaID.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: mycolors.textPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: mysizes.spacebtwsections),

                // ===== Impact List =====
                Card(
                  elevation: 0,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(mysizes.borderRadiusLg),
                    side: BorderSide(
                      color: mycolors.borderprimary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(mysizes.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _Bullet(text: 'Your data will be deleted'),
                        SizedBox(height: mysizes.sm),
                        _Bullet(text: 'Your password will be deleted'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: mysizes.spacebtwsections),

                // ===== Acknowledgement =====
                CheckboxListTile(
                  value: _acknowledged,
                  onChanged: (v) => setState(() => _acknowledged = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'I understand this action is permanent.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: mycolors.textPrimary),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: mysizes.spacebtwsections),

                // ===== Buttons =====
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isDeleting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: mysizes.btnheight),
                          side: BorderSide(
                            color: mycolors.textPrimary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                mysizes.borderRadiusLg),
                          ),
                        ),
                        child: const Text('Oops, I changed my mind!'),
                      ),
                    ),
                    const SizedBox(width: mysizes.spacebtwitems),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            (!_acknowledged || _isDeleting) ? null : _confirmDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: mysizes.btnheight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                mysizes.borderRadiusLg),
                          ),
                          elevation: 0,
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Delete my account!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // ===== OFFICIAL KITAID NAVBAR =====
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 4, // Settings tab active
        onTap: (index) {
          if (index == 4) return; // already here
          switch (index) {
            case 0:
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              break;
            case 1:
              Navigator.pushNamedAndRemoveUntil(context, '/services', (_) => false);
              break;
            case 2:
              Navigator.pushNamedAndRemoveUntil(context, '/notifications', (_) => false);
              break;
            case 3:
              Navigator.pushNamedAndRemoveUntil(context, '/settings', (_) => false);
              break;
          }
        },
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        const Icon(Icons.check_circle, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mycolors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
