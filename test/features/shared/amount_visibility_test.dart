import 'package:affluena_mobile/core/formatters/money_formatter.dart';
import 'package:affluena_mobile/features/shared/application/amount_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// The async in-memory backend lives in the platform-interface package, which is
// only a transitive dependency here; the import is test-only.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // A fresh in-memory store per test so persistence assertions are isolated.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('defaults to visible', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(amountVisibilityProvider), isTrue);
  });

  test('toggle flips the state and persists it across containers', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(amountVisibilityProvider.notifier).toggle();
    expect(container.read(amountVisibilityProvider), isFalse);

    // A fresh container (a fresh app start over the same storage) hydrates
    // the persisted "hidden" choice.
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    restarted.read(amountVisibilityProvider);
    await Future<void>.delayed(Duration.zero); // let _restore complete
    expect(restarted.read(amountVisibilityProvider), isFalse);

    // Toggling back persists "visible" again.
    await restarted.read(amountVisibilityProvider.notifier).toggle();
    final again = ProviderContainer();
    addTearDown(again.dispose);
    again.read(amountVisibilityProvider);
    await Future<void>.delayed(Duration.zero);
    expect(again.read(amountVisibilityProvider), isTrue);
  });

  test('maskedIdr renders the fixed placeholder only when hidden', () {
    expect(MoneyFormatter.maskedIdr(320000, visible: true), 'Rp 320.000');
    expect(MoneyFormatter.maskedIdr(320000, visible: false), 'Rp ••••••');
    // Fixed width regardless of magnitude — no size leak.
    expect(
      MoneyFormatter.maskedIdr(9, visible: false),
      MoneyFormatter.maskedIdr(999999999, visible: false),
    );
  });
}
