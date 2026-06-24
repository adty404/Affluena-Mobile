import 'package:flutter/material.dart';

/// Scaffold for a "drill-in" screen — one pushed onto the stack from a list or
/// the More menu. It gives every such screen the same chrome: an AppBar with
/// the screen title and an automatic back affordance (back arrow + Android
/// system back + a clear way to return to the previous screen).
///
/// Tab-root screens (the five bottom-nav destinations) do NOT use this — they
/// render their own large in-body title and have no back button.
class DrillInScaffold extends StatelessWidget {
  const DrillInScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
