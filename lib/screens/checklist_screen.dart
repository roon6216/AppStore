import 'package:flutter/material.dart';
import '../widgets/checklist_item.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    final storageService = StorageService();
    
    try {
      await authService.signOut();
      await storageService.clearUserInfo();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출장 전 체크리스트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/sheet-selection');
            },
            tooltip: '시트 선택',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '■ 출장 전 체크리스트',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '1. 차량 이용 시',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const ChecklistItem(text: '하이패스 잔액 및 사전 기안 여부 확인'),
            const ChecklistItem(text: '주유 여부 및 사전 기안 여부 확인'),
            const ChecklistItem(text: '주차 결제 여부 및 사후 기안'),
            const ChecklistItem(
              text: '★출발 전·후 미터기 확인 및 기록부 작성',
              isImportant: true,
            ),
            const ChecklistItem(text: '회의 및 필요 식대 있는지'),
            const SizedBox(height: 32),
            const Text(
              '2. 차량 미이용 시',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            const ChecklistItem(text: '교통비 잔액 및 사전 기안 여부 확인'),
            const ChecklistItem(text: '회의 및 필요 식대 있는지'),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/record-form');
              },
              icon: const Icon(Icons.edit),
              label: const Text('기록 입력하기'),
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
    );
  }
}
