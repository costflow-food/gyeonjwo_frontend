import 'package:flutter/material.dart';

/// Google light-theme button, using the official logo without recoloring.
/// https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      foregroundColor: const WidgetStatePropertyAll(Color(0xFF1F1F1F)),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFF747775))),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.padded,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused)) {
          return const Color(0x1F1F1F1F);
        }
        if (states.contains(WidgetState.hovered)) {
          return const Color(0x141F1F1F);
        }
        return Colors.transparent;
      }),
    ),
    child: Row(
      children: [
        Image.asset(
          'assets/branding/google/g-logo.png',
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Google 계정으로 계속',
            textAlign: TextAlign.center,
            style: TextStyle(
              // Google's branding size is separate from the app's size presets.
              fontFamily: 'GoogleSignInRoboto',
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.25,
            ),
          ),
        ),
      ],
    ),
  );
}
