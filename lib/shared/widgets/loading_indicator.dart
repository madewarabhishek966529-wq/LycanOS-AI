import 'package:flutter/material.dart';

/// Standard loading spinner, plus a full-screen overlay variant used while
/// a blocking operation (login, checkout submit, sync) is in flight.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({this.size = 24, super.key});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({required this.isLoading, required this.child, super.key});
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.15),
              child: const LoadingIndicator(size: 32),
            ),
          ),
      ],
    );
  }
}
