import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/user_setup_screen.dart';
import 'screens/checklist_screen.dart';
import 'screens/record_form_screen.dart';
import 'screens/sheet_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  // 주의: 실제 Firebase 프로젝트 설정 후 아래 주석을 해제하세요
  // await Firebase.initializeApp();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '출장 체크리스트',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/user-setup': (context) => const UserSetupScreen(),
        '/sheet-selection': (context) => const SheetSelectionScreen(),
        '/checklist': (context) => const ChecklistScreen(),
        '/record-form': (context) => const RecordFormScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // 인증 상태 확인
    try {
      _authService.authStateChanges.listen((user) async {
        if (user != null) {
          // 로그인된 경우, 첫 로그인 여부 확인
          final isFirstLogin = await _storageService.isFirstLogin();
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
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
        } else {
          // 로그인되지 않은 경우
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      });
    } catch (e) {
      // Firebase 초기화 오류 시 로그인 화면으로 이동
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const LoginScreen();
  }
}
