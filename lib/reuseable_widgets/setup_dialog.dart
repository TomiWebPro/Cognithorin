import 'package:flutter/material.dart';

class SetupDialog extends StatelessWidget {
  final Widget child;

  const SetupDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Material(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              margin: const EdgeInsets.all(24),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
