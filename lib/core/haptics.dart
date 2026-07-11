import 'package:flutter/services.dart';

/// The app's two haptic accents, kept deliberately subtle (Tinta is calm):
///
/// - [hapticSuccess] — a light impact on the SUCCESS path of money actions
///   (transaction create/edit/delete, quick-add save, pay flows, goal
///   contributions). Never fired on errors: the SnackBar/banner suffices,
///   and buzzing on failure reads as alarm.
/// - [hapticTap] — a selection tick for deliberate primary taps (the
///   skyConfirm accept button, quick-amount chips).
///
/// [HapticFeedback] is a platform-channel no-op in widget tests, so these are
/// safe to call from controllers and widgets alike.
void hapticSuccess() => HapticFeedback.lightImpact();

void hapticTap() => HapticFeedback.selectionClick();
