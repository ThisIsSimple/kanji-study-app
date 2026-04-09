import 'package:flutter/material.dart';

class AppSessionGate extends StatelessWidget {
  const AppSessionGate({
    super.key,
    required this.isInitialized,
    required this.hasSession,
    required this.sessionStream,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  final bool isInitialized;
  final bool hasSession;
  final Stream<bool> sessionStream;
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return unauthenticatedChild;
    }

    return StreamBuilder<bool>(
      stream: sessionStream,
      initialData: hasSession,
      builder: (context, snapshot) {
        final isAuthenticated = snapshot.data ?? hasSession;
        return isAuthenticated ? authenticatedChild : unauthenticatedChild;
      },
    );
  }
}
