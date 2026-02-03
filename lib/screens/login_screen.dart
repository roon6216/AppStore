import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (mounted && user != null) {
        // 로그인 성공 시 첫 로그인 여부 확인 후 화면 이동
        final isFirstLogin = await _storageService.isFirstLogin();
        if (isFirstLogin) {
          Navigator.of(context).pushReplacementNamed('/user-setup');
        } else {
          // 시트가 선택되었는지 확인
          final selectedSheetId = await _storageService.getSelectedSheetId();
          if (selectedSheetId == null) {
            Navigator.of(context).pushReplacementNamed('/sheet-selection');
          } else {
            Navigator.of(context).pushReplacementNamed('/checklist');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // 에러 메시지 표시
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        
        // 설정 오류인 경우 더 긴 시간 표시
        final isSetupError = errorMessage.contains('Google 로그인 설정');
        final duration = isSetupError ? const Duration(seconds: 8) : const Duration(seconds: 4);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(fontSize: 14),
            ),
            duration: duration,
            backgroundColor: Colors.red,
            action: isSetupError
                ? SnackBarAction(
                    label: '확인',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 100,
                  color: Colors.blue,
                ),
                const SizedBox(height: 32),
                const Text(
                  '출장 체크리스트',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Google 계정으로 로그인하여\n출장 기록을 관리하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset(
                          'assets/images/google_logo.png',
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.login);
                          },
                        ),
                  label: Text(_isLoading ? '로그인 중...' : 'Google로 로그인'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
