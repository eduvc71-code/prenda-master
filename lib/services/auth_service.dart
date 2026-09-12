import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    return await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  Future<http.Client?> getAuthenticatedClient() async {
    return await _googleSignIn.authenticatedClient();
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

// Provider to track auth state
final googleAuthStateProvider = StateProvider<bool>((ref) {
  final authService = ref.read(googleAuthServiceProvider);
  return authService.isSignedIn();
});

// Provider to get current user
final googleUserProvider = Provider<GoogleSignInAccount?>((ref) {
  final authService = ref.read(googleAuthServiceProvider);
  return authService.getCurrentUser();
});
