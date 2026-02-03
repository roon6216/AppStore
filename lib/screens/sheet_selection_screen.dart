import 'package:flutter/material.dart';
import '../services/sheets_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class SheetSelectionScreen extends StatefulWidget {
  const SheetSelectionScreen({super.key});

  @override
  State<SheetSelectionScreen> createState() => _SheetSelectionScreenState();
}

class _SheetSelectionScreenState extends State<SheetSelectionScreen> {
  final SheetsService _sheetsService = SheetsService(AuthService());
  final StorageService _storageService = StorageService();
  
  List<SheetInfo> _sheets = [];
  bool _isLoading = true;
  String? _selectedSheetId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSheets();
    _loadSavedSheet();
  }

  Future<void> _loadSavedSheet() async {
    final savedSheetId = await _storageService.getSelectedSheetId();
    if (savedSheetId != null) {
      setState(() {
        _selectedSheetId = savedSheetId;
      });
    }
  }

  Future<void> _loadSheets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sheets = await _sheetsService.getAvailableSheets();
      setState(() {
        _sheets = sheets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '시트 목록을 불러올 수 없습니다: ${e.toString().split(':').last.trim()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSheetSelection() async {
    if (_selectedSheetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시트를 선택해주세요')),
      );
      return;
    }

    try {
      await _storageService.saveSelectedSheetId(_selectedSheetId!);
      // 시트 변경 시 캐시 초기화
      _sheetsService.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시트가 선택되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        // 체크리스트 화면에서 설정으로 온 경우 뒤로가기, 아니면 체크리스트로 이동
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/checklist');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시트 선택'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '사용할 시트를 선택하세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadSheets,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_sheets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('사용 가능한 시트가 없습니다'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _sheets.length,
                    itemBuilder: (context, index) {
                      final sheet = _sheets[index];
                      final isSelected = _selectedSheetId == sheet.id.toString();
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          title: Text(
                            sheet.title,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: sheet.rowCount > 0
                              ? Text('${sheet.rowCount}개 행')
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedSheetId = sheet.id.toString();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading || _selectedSheetId == null ? null : _saveSheetSelection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('선택 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

