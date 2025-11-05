// TODO Implement this library.
// lib/features/auth/signup/widgets/otp_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';

class OtpFields extends StatefulWidget {
  const OtpFields({
    super.key,
    this.length = 4,
    this.onCompleted,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<OtpFields> {
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  void _updateAndNotify() {
    final code = _ctrls.map((c) => c.text).join();
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      widget.onCompleted?.call(code);
    }
  }

  void _handlePaste(String text) {
    final cleaned = text.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length; i++) {
      _ctrls[i].text = i < cleaned.length ? cleaned[i] : '';
    }
    // Move focus to end
    int idx = cleaned.length.clamp(0, widget.length - 1);
    _nodes[idx].requestFocus();
    _updateAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    final boxes = List<Widget>.generate(widget.length, (i) {
      return SizedBox(
        width: 60,
        child: TextField(
          controller: _ctrls[i],
          focusNode: _nodes[i],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            color: mycolors.textPrimary,
            fontSize: mysizes.fontLg,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,                     // ✅ white background
            fillColor: Colors.white,          // ✅ fill each OTP box
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
              borderSide: const BorderSide(color: mycolors.borderprimary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
              borderSide: const BorderSide(color: mycolors.borderprimary, width: 2),
            ),
            hintText: '•',
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (v) {
            if (v.length == 1 && i < widget.length - 1) {
              _nodes[i + 1].requestFocus();
            }
            if (v.isEmpty && i > 0) {
              _nodes[i - 1].requestFocus();
            }
            _updateAndNotify();
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          
        ),
      );
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () async {
        final data = await Clipboard.getData('text/plain');
        final text = data?.text ?? '';
        if (text.isNotEmpty) _handlePaste(text);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: boxes,
      ),
    );
  }
}
