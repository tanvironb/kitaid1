import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  BiometricAuthService._();
  static final BiometricAuthService instance = BiometricAuthService._();

  static const _prefKeyEnabled = 'biometric_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  ///  More reliable support check:
  /// - if devices return canCheckBiometrics=false even if device supports biometrics
  Future<bool> isDeviceSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      return supported && (canCheck || available.isNotEmpty);
    } catch (_) {
      return false;
    }
  }

  ///  True if at least one biometric is enrolled
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  ///  UI helper: Face supported
  Future<bool> supportsFace() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.contains(BiometricType.face);
    } catch (_) {
      return false;
    }
  }

  ///  UI helper: Fingerprint supported/enrolled?
  Future<bool> supportsFingerprint() async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.contains(BiometricType.fingerprint);
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, value);
  }

  ///  This will trigger Face ID on iOS / Face Unlock on Android automatically if available.
  Future<bool> authenticate({String reason = 'Verify your identity'}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok;
    } catch (_) {
      return false;
    }
  }
}
