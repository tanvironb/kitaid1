// lib/features/settings/delete_account_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _acknowledged = false;
  bool _isDeleting = false;

  Future<void> _deleteCollectionInBatches({
    required CollectionReference<Map<String, dynamic>> colRef,
    int batchSize = 300,
  }) async {
    while (true) {
      final snap = await colRef.limit(batchSize).get();
      if (snap.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteUserDataEverywhere(String uid) async {
    final userDoc = FirebaseFirestore.instance.collection('Users').doc(uid);

    // delete subcollections first (cards, docs). Add more if you create later.
    await _deleteCollectionInBatches(
      colRef: userDoc.collection('cards'),
    );
    await _deleteCollectionInBatches(
      colRef: userDoc.collection('docs'),
    );

    // finally delete the user main doc
    await userDoc.delete();
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm deletion'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'Are you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: _isDeleting ? null : () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged-in user. Please login again.');
      }

      final uid = user.uid;

      // 1) Delete Firestore data
      await _deleteUserDataEverywhere(uid);

      // 2) Delete Auth user
      await user.delete();

      // 3) Sign out (safe cleanup)
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been deleted.')),
      );

      // Go to login page and clear stack
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);

      // Most common:
      // requires-recent-login => user must re-login then delete again
      final msg = switch (e.code) {
        'requires-recent-login' =>
          'For security, please login again then try deleting your account.',
        _ => e.message ?? 'Delete failed.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
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
                Container(
                  padding: const EdgeInsets.all(mysizes.lg),
                  decoration: BoxDecoration(
                    color: mycolors.Primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 40, color: error),
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
                Card(
                  elevation: 0,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(mysizes.borderRadiusLg),
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
                        _Bullet(text: 'Your data will be deleted (profile, cards, docs)'),
                        SizedBox(height: mysizes.sm),
                        _Bullet(text: 'Your login account will be deleted (Firebase Auth)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: mysizes.spacebtwsections),
                CheckboxListTile(
                  value: _acknowledged,
                  onChanged: _isDeleting
                      ? null
                      : (v) => setState(() => _acknowledged = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'I understand this action is permanent.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: mycolors.textPrimary),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: mysizes.spacebtwsections),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isDeleting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: mysizes.btnheight),
                          side: BorderSide(
                            color: mycolors.textPrimary.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(mysizes.borderRadiusLg),
                          ),
                        ),
                        child: const Text('Oops, I changed my mind!'),
                      ),
                    ),
                    const SizedBox(width: mysizes.spacebtwitems),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!_acknowledged || _isDeleting)
                            ? null
                            : _confirmDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: mysizes.btnheight),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(mysizes.borderRadiusLg),
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
        currentIndex: 4,
        onTap: (index) {
          if (index == 4) return;
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
