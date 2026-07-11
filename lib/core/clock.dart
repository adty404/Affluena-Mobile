import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's wall clock. Production reads real time; tests/goldens override
/// this with a fixed instant so time-bearing UI (e.g. Beranda's
/// "Diperbarui HH.mm" stamp) renders deterministically.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);
