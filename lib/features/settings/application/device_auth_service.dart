import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final deviceAuthServiceProvider = Provider<DeviceAuthService>((ref) {
  return LocalDeviceAuthService(LocalAuthentication());
});

abstract interface class DeviceAuthService {
  Future<bool> isSupported();

  Future<bool> authenticate();
}

class LocalDeviceAuthService implements DeviceAuthService {
  const LocalDeviceAuthService(this._localAuthentication);

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> isSupported() async {
    try {
      return await _localAuthentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    return _localAuthentication.authenticate(
      localizedReason: 'Authenticate to protect your Affluena session.',
      biometricOnly: false,
      sensitiveTransaction: true,
      persistAcrossBackgrounding: true,
    );
  }
}
