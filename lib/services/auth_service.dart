import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';

class AuthService {
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  FirebaseAuth get _firebaseAuth {
    _auth ??= FirebaseAuth.instance;
    return _auth!;
  }

  GoogleSignIn get _googleSignInInstance {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.readonly',
      ],
    );
    return _googleSignIn!;
  }

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Stream<UserModel?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges().map(
            (user) {
              if (user != null) {
                _currentUser = UserModel(
                  uid: user.uid,
                  email: user.email ?? '',
                  displayName: user.displayName,
                  photoUrl: user.photoURL,
                );
                return _currentUser;
              }
              _currentUser = null;
              return null;
            },
          );
    } catch (e) {
      // Firebase가 초기화되지 않은 경우 빈 스트림 반환
      return Stream<UserModel?>.value(null);
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) {
        // 사용자가 로그인을 취소한 경우
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase가 초기화되지 않은 경우에도 Google Sign-In 정보만 사용
      try {
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        if (userCredential.user != null) {
          _currentUser = UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName,
            photoUrl: userCredential.user!.photoURL,
          );
          return _currentUser;
        }
      } catch (firebaseError) {
        // Firebase 초기화 오류인 경우, Google Sign-In 정보만 사용
        _currentUser = UserModel(
          uid: googleUser.id,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl,
        );
        return _currentUser;
      }

      return null;
    } on PlatformException catch (e) {
      // PlatformException 처리 (에러 코드 10 포함)
      if (e.code == 'sign_in_failed' || e.message?.contains('10') == true) {
        // 설정 오류 안내
        throw Exception(
          'Google 로그인 설정이 필요합니다.\n\n'
          '다음 단계를 진행하세요:\n'
          '1. Google Cloud Console 접속\n'
          '2. OAuth 클라이언트 ID 생성 (Android)\n'
          '3. AndroidManifest.xml에 클라이언트 ID 추가\n\n'
          '자세한 내용은 SETUP_GOOGLE_SIGNIN.md 파일을 참고하세요.'
        );
      }
      rethrow;
    } catch (e) {
      // 기타 에러는 원본 메시지 유지하되 간단하게
      final errorMsg = e.toString();
      if (errorMsg.contains('10') || errorMsg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google 로그인 설정이 필요합니다.\n\n'
          'SETUP_GOOGLE_SIGNIN.md 파일을 참고하여 설정을 완료하세요.'
        );
      }
      throw Exception('로그인 실패: ${e.toString().split(':').last.trim()}');
    }
  }

  Future<void> signOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
    if (_auth != null) {
      await _auth!.signOut();
    }
    _currentUser = null;
  }

  Future<String?> getAccessToken() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signInSilently();
      if (googleUser == null) {
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      return googleAuth.accessToken;
    } catch (e) {
      return null;
    }
  }
}
