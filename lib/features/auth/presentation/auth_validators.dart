/// Client-side validators shared across auth + settings password surfaces.
///
/// Keep messages user-facing and free of jargon. These mirror the API rules
/// (email shape, 8-char minimum) so users get instant feedback before submit.
abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Returns an error message for an invalid email, or null when valid.
  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Returns an error message for a weak/empty password, or null when valid.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter a password.';
    if (text.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  /// Returns an error when [confirmation] does not match [password].
  static String? confirmPassword(String? password, String? confirmation) {
    final confirm = confirmation ?? '';
    if (confirm.isEmpty) return 'Re-enter your password.';
    if (confirm != (password ?? '')) return 'Passwords do not match.';
    return null;
  }

  /// Returns an error for an empty reset code, or null when present.
  ///
  /// We deliberately call this "the code from your email" in copy, not "token".
  static String? resetCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the code from your email.';
    return null;
  }

  static String? required(String? value, {required String message}) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }
}
