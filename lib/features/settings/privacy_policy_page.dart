import 'package:flutter/material.dart';
// import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';


class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy',textAlign: TextAlign.center,),

        backgroundColor: mycolors.Primary,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                // Header
                Text('Privacy Policy for KitaID', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Last updated: June 03, 2025', style: textTheme.bodyMedium?.copyWith(color: mycolors.textPrimary)),
                const SizedBox(height: 16),

                // Intro
                _CardBlock(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _P(textTheme,
                          'This Privacy Policy describes our policies and procedures on the collection, use and disclosure of your information when you use the Service and tells you about your privacy rights and how the law protects you.'),
                      _P(textTheme,
                          'We use your personal data to provide and improve the Service. By using the Service, you agree to the collection and use of information in accordance with this Privacy Policy.'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                _H2(textTheme, 'Interpretation and Definitions'),
                _H3(textTheme, 'Interpretation'),
                _P(textTheme,
                    'Words with the initial letter capitalized have meanings defined under the following conditions. The following definitions shall have the same meaning whether they appear in singular or plural.'),

                _H3(textTheme, 'Definitions'),
                _BulletList(textTheme, const [
                  'Account: A unique account created for you to access our Service or parts of our Service.',
                  'Affiliate: An entity that controls, is controlled by, or is under common control with a party.',
                  'Application: KitaID, the software program provided by the Company.',
                  'Company: Referred to as "the Company", "We", "Us" or "Our" — KitaID.',
                  'Country: Malaysia.',
                  'Device: Any device that can access the Service such as a computer, cellphone or digital tablet.',
                  'Personal Data: Any information that relates to an identified or identifiable individual.',
                  'Service: The Application.',
                  'Service Provider: Any natural or legal person who processes data on behalf of the Company.',
                  'Usage Data: Data collected automatically (e.g., IP address, browser type, pages visited, timestamps).',
                  'You: The individual using the Service, or the company/other legal entity on whose behalf the Service is used.',
                ]),

                const SizedBox(height: 20),
                _H2(textTheme, 'Collecting and Using Your Personal Data'),
                _H3(textTheme, 'Types of Data Collected'),
                _H4(textTheme, 'Personal Data'),
                _P(textTheme, 'While using our Service, we may ask you to provide certain personally identifiable information that can be used to contact or identify you, including:'),
                _BulletList(textTheme, const [
                  'Email address',
                  'First name and last name',
                  'Phone number',
                  'Usage Data',
                ]),

                _H4(textTheme, 'Usage Data'),
                _P(textTheme,
                    'Usage Data is collected automatically and may include your device’s IP address, browser type/version, pages visited, time/date of visit, time spent on pages, unique device identifiers, and other diagnostic data.'),
                _P(textTheme,
                    'When accessing via a mobile device, we may collect device type, unique ID, IP address, operating system, mobile browser type, unique identifiers, and diagnostic data.'),

                _H4(textTheme, 'Information Collected while Using the Application'),
                _P(textTheme, 'With your prior permission, the Application may collect:'),
                _BulletList(textTheme, const [
                  'Information regarding your location',
                  "Pictures and other information from your device's camera and photo library",
                ]),
                _P(textTheme,
                    'We use this information to provide features of our Service and to improve/customize it. Information may be uploaded to Company or Service Provider servers, or stored locally on your device. You can enable or disable access at any time via your device settings.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Use of Your Personal Data'),
                _P(textTheme, 'The Company may use Personal Data for the following purposes:'),
                _BulletList(textTheme, const [
                  'To provide and maintain our Service, including monitoring usage.',
                  'To manage your Account and provide registered-user functionalities.',
                  'For the performance of a contract, including purchases or other agreements made through the Service.',
                  'To contact you via email, calls, SMS, or push notifications about updates and security notices.',
                  'To provide you with news, special offers, and general information about similar goods/services unless you opt out.',
                  'To manage your requests to us.',
                  'For business transfers (e.g., merger, sale, financing) where user data may be part of transferred assets.',
                  'For other purposes such as data analysis, usage trends, campaign effectiveness, and overall service improvement.',
                ]),
                _P(textTheme, 'We may share your personal information in the following situations:'),
                _BulletList(textTheme, const [
                  'With Service Providers to monitor/analyze usage or to contact you.',
                  'For business transfers in connection with mergers or acquisitions.',
                  'With Affiliates that will be required to honor this Privacy Policy.',
                  'With business partners to offer certain products, services, or promotions.',
                  'With other users when you share information in public areas of the Service.',
                  'With your consent for any other purpose.',
                ]),

                const SizedBox(height: 20),
                _H2(textTheme, 'Retention of Your Personal Data'),
                _P(textTheme,
                    'We retain Personal Data only as long as necessary for the purposes set out in this Policy and to comply with legal obligations, resolve disputes, and enforce agreements. Usage Data is generally retained for a shorter period unless needed to strengthen security, improve functionality, or where longer retention is legally required.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Transfer of Your Personal Data'),
                _P(textTheme,
                    'Your information may be processed and stored in locations where the parties involved are based, which may be outside your jurisdiction. We take reasonable steps to ensure your data is treated securely and in accordance with this Policy and that no transfer occurs without adequate controls in place.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Delete Your Personal Data'),
                _P(textTheme,
                    'You have the right to delete or request assistance deleting Personal Data we have collected about you. Where available, you can delete certain information within the Service or by managing your account settings. You may also contact us to request access, correction, or deletion. We may retain information where we have a legal obligation or lawful basis.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Disclosure of Your Personal Data'),
                _H3(textTheme, 'Business Transactions'),
                _P(textTheme,
                    'If the Company is involved in a merger, acquisition, or asset sale, your Personal Data may be transferred. We will provide notice before such transfer becomes subject to a different policy.'),
                _H3(textTheme, 'Law Enforcement'),
                _P(textTheme,
                    'Under certain circumstances, we may be required to disclose Personal Data if required by law or in response to valid requests by public authorities.'),
                _H3(textTheme, 'Other Legal Requirements'),
                _P(textTheme, 'We may disclose Personal Data in good faith when necessary to:'),
                _BulletList(textTheme, const [
                  'Comply with a legal obligation',
                  'Protect and defend the rights or property of the Company',
                  'Prevent or investigate possible wrongdoing in connection with the Service',
                  'Protect the personal safety of users or the public',
                  'Protect against legal liability',
                ]),

                const SizedBox(height: 20),
                _H2(textTheme, 'Security of Your Personal Data'),
                _P(textTheme,
                    'We strive to use commercially acceptable means to protect your Personal Data, but no method of transmission or electronic storage is 100% secure. We cannot guarantee absolute security.'),

                const SizedBox(height: 20),
                _H2(textTheme, "Children's Privacy"),
                _P(textTheme,
                    'Our Service does not address anyone under the age of 13, and we do not knowingly collect personal information from children under 13. If you believe a child has provided us with Personal Data, please contact us so we can take appropriate action.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Links to Other Websites'),
                _P(textTheme,
                    'Our Service may contain links to third-party websites not operated by us. We strongly advise you to review the privacy policy of every site you visit. We have no control over and assume no responsibility for third-party content, privacy policies, or practices.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Changes to this Privacy Policy'),
                _P(textTheme,
                    'We may update this Privacy Policy from time to time. We will notify you by posting the new Policy on this page and will update the “Last updated” date. We may also notify you via email and/or a prominent in-app notice before changes become effective.'),

                const SizedBox(height: 20),
                _H2(textTheme, 'Contact Us'),
                _P(textTheme,
                    'If you have any questions about this Privacy Policy, you can contact us by email: monirsa2002@gmail.com'),
                const SizedBox(height: 8),
                // _Note(textTheme,
                //     'This policy contains language adapted from the user-provided document (Free Privacy Policy Generator). Replace placeholders and add any Malaysia-specific legal notices or PDPA references if required by your counsel.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------- Small helpers below keep the main build() readable -------

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
        border: Border.all(color: mycolors.borderprimary.withValues(alpha: 140)),
      ),
      child: child,
    );
  }
}

Widget _H2(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700,fontSize: mysizes.fontMd,)),
    );

Widget _H3(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(text, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w500,fontSize: mysizes.fontMd,)),
    );

Widget _H4(TextTheme t, String text) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(text, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700,fontSize: mysizes.fontMd,)),
    );

Widget _P(TextTheme t, String text) =>
    Padding(padding: const EdgeInsets.only(bottom: 8), 
    child: 
    Text(text, 
    style: t.bodyMedium?.copyWith(
          fontSize: mysizes.fontSm,)));

class _BulletList extends StatelessWidget {
  const _BulletList(this.textTheme, this.items);
  final TextTheme textTheme;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(e, 
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: mysizes.fontSm,

                    ))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.textTheme, this.text);
  final TextTheme textTheme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(.5),
        borderRadius: BorderRadius.circular(mysizes.borderRadiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: textTheme.bodySmall?.copyWith(
            fontSize: mysizes.fontSm
          ))),
        ],
      ),
    );
  }
}
