import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/sheets_service.dart';
import '../services/auth_service.dart';
import '../models/trip_record_model.dart';
import '../models/dropdown_options.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/dropdown_field.dart';

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key});

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final SheetsService _sheetsService = SheetsService(AuthService());

  DateTime _useDate = DateTime.now();
  String? _department;
  String? _name;
  int? _beforeOdometer;
  int? _afterOdometer;
  int? _usedDistance;
  int? _commuteDistance;
  int? _businessDistance;
  String? _destination;
  int? _paymentAmount;
  int? _fuelCost;
  int? _repairCost;

  DropdownOptions _dropdownOptions = DropdownOptions.empty();
  bool _isLoading = false;
  bool _isInitialized = false; // 초기화 완료 여부

  final TextEditingController _beforeOdometerController = TextEditingController();
  final TextEditingController _afterOdometerController = TextEditingController();
  final TextEditingController _usedDistanceController = TextEditingController();
  final TextEditingController _commuteController = TextEditingController();
  final TextEditingController _businessController = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();
  final TextEditingController _fuelController = TextEditingController();
  final TextEditingController _repairController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 날짜 컨트롤러 초기값 설정 (즉시 실행)
    _dateController.text = '${_useDate.year}. ${_useDate.month.toString().padLeft(2, '0')}. ${_useDate.day.toString().padLeft(2, '0')}';
    
    // 화면을 즉시 표시하고, 데이터는 첫 프레임 후 로드
    // Future.microtask를 사용하여 현재 프레임이 완료된 후 실행
    Future.microtask(() {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  // 초기 데이터 로드 (화면이 먼저 렌더링된 후 실행)
  Future<void> _loadInitialData() async {
    // 1. 사용자 정보 로드
    final department = await _storageService.getDepartment();
    final name = await _storageService.getName();
    
    if (mounted) {
      setState(() {
        _department = department;
        _name = name;
        _isInitialized = true; // 초기화 완료 표시
      });
      
      if (name != null) {
        _nameController.text = name;
      }
    }

    // 2. 시트 확인 (없으면 이동)
    final selectedSheetId = await _storageService.getSelectedSheetId();
    if (selectedSheetId == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/sheet-selection');
      }
      return;
    }

    // 3. 추가 데이터 로드 (백그라운드에서, 에러 발생해도 계속 진행)
    _loadAdditionalData();
  }

  // 추가 데이터 로드 (백그라운드)
  Future<void> _loadAdditionalData() async {
    // 마지막 주행 후 거리 로드
    try {
      final lastOdometer = await _sheetsService.readLastOdometer();
      if (lastOdometer != null && mounted) {
        setState(() {
          _beforeOdometer = lastOdometer;
        });
        _beforeOdometerController.text = lastOdometer.toString();
      }
    } catch (e) {
      // 주행 거리 읽기 실패해도 계속 진행
    }

    // 드롭다운 옵션 로드
    try {
      final options = await _sheetsService.getDropdownOptions();
      if (mounted) {
        setState(() {
          _dropdownOptions = options;
        });
      }
    } catch (e) {
      // 드롭다운 옵션 로드 실패해도 계속 진행
    }
  }

  void _calculateDistance() {
    if (_beforeOdometer != null && _afterOdometer != null) {
      setState(() {
        _usedDistance = _afterOdometer! - _beforeOdometer!;
        _usedDistanceController.text = _usedDistance?.toString() ?? '';
      });
    } else {
      setState(() {
        _usedDistance = null;
        _usedDistanceController.text = '';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 데이터 검증 강화
    if (_department == null || _department!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부서를 선택해주세요')),
      );
      return;
    }

    if (_name == null || _name!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성명을 확인해주세요')),
      );
      return;
    }

    if (_beforeOdometer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주행 전 거리를 확인해주세요')),
      );
      return;
    }

    if (_afterOdometer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주행 후 거리를 입력해주세요')),
      );
      return;
    }

    if (_afterOdometer! < _beforeOdometer!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주행 후 거리는 주행 전 거리보다 커야 합니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final record = TripRecord(
        useDate: _useDate,
        department: _department!,
        name: _name!,
        beforeOdometer: _beforeOdometer,
        afterOdometer: _afterOdometer,
        usedDistance: _usedDistance,
        commuteDistance: _commuteDistance,
        businessDistance: _businessDistance,
        destination: _destinationController.text.trim().isEmpty 
            ? null 
            : _destinationController.text.trim(),
        paymentAmount: _paymentAmount,
        fuelCost: _fuelCost,
        repairCost: _repairCost,
        other: _otherController.text.trim().isEmpty
            ? null
            : _otherController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _sheetsService.appendRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기록이 성공적으로 저장되었습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 실패: $errorMessage',
              style: const TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
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
  void dispose() {
    _beforeOdometerController.dispose();
    _afterOdometerController.dispose();
    _usedDistanceController.dispose();
    _commuteController.dispose();
    _businessController.dispose();
    _paymentController.dispose();
    _fuelController.dispose();
    _repairController.dispose();
    _otherController.dispose();
    _notesController.dispose();
    _destinationController.dispose();
    _nameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 화면이 즉시 표시되도록 보장
    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 입력'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '사용일자',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                controller: _dateController,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _useDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != _useDate) {
                    setState(() {
                      _useDate = picked;
                      _dateController.text = '${picked.year}. ${picked.month.toString().padLeft(2, '0')}. ${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '사용일자를 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '부서',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                value: _department,
                items: const [
                  DropdownMenuItem<String>(
                    value: '부산본부',
                    child: Text('부산본부'),
                  ),
                  DropdownMenuItem<String>(
                    value: '대전본부',
                    child: Text('대전본부'),
                  ),
                  DropdownMenuItem<String>(
                    value: '서울본부',
                    child: Text('서울본부'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _department = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '부서를 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '성명',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  helperText: '저장된 이름이 자동으로 입력됩니다',
                ),
                readOnly: true, // 저장된 이름은 읽기 전용
                style: const TextStyle(color: Colors.grey),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '성명을 확인해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _beforeOdometerController,
                decoration: const InputDecoration(
                  labelText: '주행 전 주행거리 (km)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  helperText: '마지막 주행 후 거리가 자동으로 입력됩니다',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: true, // 자동으로 채워지므로 읽기 전용
                style: const TextStyle(color: Colors.grey),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주행 전 거리를 확인해주세요';
                  }
                  return null;
                },
                // onChanged 제거 - readOnly이므로 변경 불가
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _afterOdometerController,
                decoration: const InputDecoration(
                  labelText: '주행 후 주행거리 (km)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  setState(() {
                    _afterOdometer = value.isEmpty ? null : int.tryParse(value);
                  });
                  _calculateDistance();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주행 후 거리를 입력해주세요';
                  }
                  if (_beforeOdometer != null &&
                      int.tryParse(value)! < _beforeOdometer!) {
                    return '주행 후 거리는 주행 전 거리보다 커야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usedDistanceController,
                decoration: const InputDecoration(
                  labelText: '사용거리 (km)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  helperText: '자동 계산됩니다',
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commuteController,
                decoration: const InputDecoration(
                  labelText: '출.퇴근용 (km)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _commuteDistance = value.isEmpty ? null : int.tryParse(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _businessController,
                decoration: const InputDecoration(
                  labelText: '일반업무용 (km)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _businessDistance = value.isEmpty ? null : int.tryParse(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: '목적지',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _destination = value.trim().isEmpty ? null : value.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentController,
                decoration: const InputDecoration(
                  labelText: '결제금액 (원)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _paymentAmount = value.isEmpty ? null : int.tryParse(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fuelController,
                decoration: const InputDecoration(
                  labelText: '유류비',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _fuelCost = value.isEmpty ? null : int.tryParse(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repairController,
                decoration: const InputDecoration(
                  labelText: '수선비',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  _repairCost = value.isEmpty ? null : int.tryParse(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otherController,
                decoration: const InputDecoration(
                  labelText: '기타',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '비고',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('전송'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
