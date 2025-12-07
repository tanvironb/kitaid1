// lib/features/settings/contact_page.dart
import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    const phoneNumber = '+60183662437';
    const emailAddress = 'monirsa2002@gmail.com';

    // ❗ NO SCAFFOLD – this is just the bottom sheet content.
    return SafeArea(
      top: false, // keep top area for the Settings page
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(
            color: mycolors.Primary,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, -2),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 3,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: mycolors.Primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contact Us',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: mycolors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mycolors.Primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),

            // phone
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.phone_outlined,
                size: 22,
                color: theme.iconTheme.color,
              ),
              title: Text(
                phoneNumber,
                style: textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                ),
              ),
              onTap: () => _launchPhone(phoneNumber),
            ),

            Divider(height: 1, color: theme.dividerColor),

            // email
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.email_outlined,
                size: 22,
                color: theme.iconTheme.color,
              ),
              title: Text(
                emailAddress,
                style: textTheme.bodyMedium?.copyWith(
                  color: mycolors.textPrimary,
                ),
              ),
              onTap: () => _launchEmail(emailAddress),
            ),
          ],
        ),
      ),
    );
  }
}
