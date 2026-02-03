import 'package:googleapis/sheets/v4.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import '../models/trip_record_model.dart';
import '../models/dropdown_options.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class SheetInfo {
  final int id;
  final String title;
  final int rowCount;

  SheetInfo({
    required this.id,
    required this.title,
    required this.rowCount,
  });
}

class SheetsService {
  static const String _spreadsheetId =
      '1ZSIJRthPVGFYvM6pFih1U658zx97wjlpnxaSk-2Wh5A';
  static const int _defaultSheetId = 276261079;

  final AuthService _authService;
  String? _cachedSheetName;
  int? _cachedSheetId;

  SheetsService(this._authService);

  // 캐시 초기화 (시트 변경 시 호출)
  void clearCache() {
    _cachedSheetName = null;
    _cachedSheetId = null;
  }

  // 저장된 시트 ID 가져오기
  Future<int> _getSheetId() async {
    // 캐시가 있으면 사용
    if (_cachedSheetId != null) {
      return _cachedSheetId!;
    }

    // 저장된 시트 ID 가져오기
    final storageService = StorageService();
    final savedSheetId = await storageService.getSelectedSheetId();
    if (savedSheetId != null) {
      final parsedId = int.tryParse(savedSheetId);
      if (parsedId != null) {
        _cachedSheetId = parsedId;
        return _cachedSheetId!;
      }
    }
    
    // 기본값 사용
    _cachedSheetId = _defaultSheetId;
    return _cachedSheetId!;
  }

  // 사용 가능한 시트 목록 가져오기
  Future<List<SheetInfo>> getAvailableSheets() async {
    try {
      final sheetsApi = await _getSheetsApi();
      final spreadsheet = await sheetsApi.spreadsheets.get(_spreadsheetId);
      
      List<SheetInfo> sheets = [];
      
      if (spreadsheet.sheets != null) {
        for (final sheet in spreadsheet.sheets!) {
          final sheetId = sheet.properties?.sheetId;
          final title = sheet.properties?.title ?? 'Sheet1';
          
          // 각 시트의 행 개수 가져오기
          int rowCount = 0;
          try {
            final response = await sheetsApi.spreadsheets.values.get(
              _spreadsheetId,
              '$title!A:A',
            );
            if (response.values != null) {
              rowCount = response.values!.length;
            }
          } catch (e) {
            // 행 개수 가져오기 실패해도 계속 진행
          }
          
          if (sheetId != null) {
            sheets.add(SheetInfo(
              id: sheetId,
              title: title,
              rowCount: rowCount,
            ));
          }
        }
      }
      
      return sheets;
    } catch (e) {
      throw Exception('시트 목록 가져오기 실패: $e');
    }
  }

  // 시트 이름을 동적으로 가져오기
  Future<String> _getSheetName() async {
    if (_cachedSheetName != null) {
      return _cachedSheetName!;
    }

    try {
      final sheetsApi = await _getSheetsApi();
      final sheetId = await _getSheetId();
      final spreadsheet = await sheetsApi.spreadsheets.get(_spreadsheetId);
      
      print('찾는 시트 ID: $sheetId');
      
      if (spreadsheet.sheets != null) {
        print('전체 시트 목록:');
        for (final sheet in spreadsheet.sheets!) {
          final id = sheet.properties?.sheetId;
          final title = sheet.properties?.title ?? 'Sheet1';
          print('  - ID: $id, 이름: $title');
          if (id == sheetId) {
            _cachedSheetName = title;
            print('시트 이름 찾음: $_cachedSheetName');
            return _cachedSheetName!;
          }
        }
        // 시트 ID로 찾지 못한 경우 첫 번째 시트 사용
        if (spreadsheet.sheets!.isNotEmpty) {
          _cachedSheetName = spreadsheet.sheets!.first.properties?.title ?? 'Sheet1';
          print('시트 ID로 찾지 못함. 첫 번째 시트 사용: $_cachedSheetName');
          return _cachedSheetName!;
        }
      }
    } catch (e) {
      print('시트 이름 가져오기 에러: $e');
    }
    
    _cachedSheetName = 'Sheet1';
    return _cachedSheetName!;
  }

  Future<SheetsApi> _getSheetsApi() async {
    // Google Sign-In에서 직접 토큰 가져오기
    try {
      final googleSignIn = GoogleSignIn(
        scopes: [
          'https://www.googleapis.com/auth/spreadsheets',
          'https://www.googleapis.com/auth/drive.readonly',
        ],
      );
      
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser == null) {
        throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      
      if (accessToken == null) {
        throw Exception('액세스 토큰을 가져올 수 없습니다. 다시 로그인해주세요.');
      }

      // 커스텀 HTTP 클라이언트 생성 (인증 헤더 추가)
      final authClient = _AuthenticatedClient(accessToken);

      return SheetsApi(authClient);
    } catch (e) {
      throw Exception('Google Sheets API 접근 실패: $e');
    }
  }

  // 마지막 주행 후 거리 읽기 (E열과 F열 모두 확인)
  Future<int?> readLastOdometer() async {
    try {
      final sheetsApi = await _getSheetsApi();
      final sheetName = await _getSheetName();
      
      // E열(주행 전 주행거리)과 F열(주행 후 주행거리) 모두 읽기
      final eColumnResponse = await sheetsApi.spreadsheets.values.get(
        _spreadsheetId,
        '$sheetName!E:E', // E열 전체
      );
      
      final fColumnResponse = await sheetsApi.spreadsheets.values.get(
        _spreadsheetId,
        '$sheetName!F:F', // F열 전체
      );

      if ((eColumnResponse.values == null || eColumnResponse.values!.isEmpty) &&
          (fColumnResponse.values == null || fColumnResponse.values!.isEmpty)) {
        return null;
      }

      // 두 열의 행 개수가 같다고 가정하고, 마지막 행부터 역순으로 확인
      final maxLength = (eColumnResponse.values?.length ?? 0) > (fColumnResponse.values?.length ?? 0)
          ? (eColumnResponse.values?.length ?? 0)
          : (fColumnResponse.values?.length ?? 0);

      // 마지막 행부터 역순으로 확인
      int? lastOdometer;
      for (int i = maxLength - 1; i >= 0; i--) {
        // F열 먼저 확인 (주행 후 주행거리가 있으면 그것을 사용)
        if (fColumnResponse.values != null && 
            i < fColumnResponse.values!.length &&
            fColumnResponse.values![i].isNotEmpty) {
          final fValue = fColumnResponse.values![i][0].toString().trim();
          if (fValue != '-' && fValue.isNotEmpty) {
            try {
              lastOdometer = int.parse(fValue.replaceAll(',', '').replaceAll(' ', ''));
              break; // F열 값이 있으면 그것을 사용하고 종료
            } catch (e) {
              // 숫자로 변환 실패 시 계속 진행
            }
          }
        }
        
        // F열이 비어있으면 E열 확인 (주행 전 주행거리)
        if (lastOdometer == null && 
            eColumnResponse.values != null && 
            i < eColumnResponse.values!.length &&
            eColumnResponse.values![i].isNotEmpty) {
          final eValue = eColumnResponse.values![i][0].toString().trim();
          if (eValue != '-' && eValue.isNotEmpty) {
            try {
              lastOdometer = int.parse(eValue.replaceAll(',', '').replaceAll(' ', ''));
              break; // E열 값이 있으면 그것을 사용하고 종료
            } catch (e) {
              // 숫자로 변환 실패 시 계속 진행
            }
          }
        }
      }

      return lastOdometer;
    } catch (e) {
      // 에러 메시지 분석
      final errorMsg = e.toString();
      if (errorMsg.contains('400') || errorMsg.contains('INVALID_ARGUMENT')) {
        throw Exception('스프레드시트 형식 오류입니다. 시트 이름을 확인해주세요.');
      } else if (errorMsg.contains('403') || errorMsg.contains('PERMISSION_DENIED')) {
        throw Exception('스프레드시트 접근 권한이 없습니다. 스프레드시트를 공유해주세요.');
      } else if (errorMsg.contains('404') || errorMsg.contains('NOT_FOUND')) {
        throw Exception('스프레드시트를 찾을 수 없습니다. 스프레드시트 ID를 확인해주세요.');
      }
      throw Exception('주행 거리 읽기 실패: $e');
    }
  }

  // 드롭다운 목록 가져오기
  Future<DropdownOptions> getDropdownOptions() async {
    try {
      final sheetsApi = await _getSheetsApi();
      final sheetName = await _getSheetName();
      
      List<String> departments = [];
      List<String> destinations = [];

      // B열 (부서) 읽기
      final deptResponse = await sheetsApi.spreadsheets.values.get(
        _spreadsheetId,
        '$sheetName!B:B',
      );
      
      // I열 (목적지) 읽기
      final destResponse = await sheetsApi.spreadsheets.values.get(
        _spreadsheetId,
        '$sheetName!I:I',
      );

      if (deptResponse.values != null) {
        departments = deptResponse.values!
            .skip(1) // 헤더 제외
            .where((row) => row.isNotEmpty && row[0].toString().trim().isNotEmpty)
            .map((row) => row[0].toString().trim())
            .where((value) => value != '-' && value.isNotEmpty)
            .toSet()
            .toList();
      }

      if (destResponse.values != null) {
        destinations = destResponse.values!
            .skip(1) // 헤더 제외
            .where((row) => row.isNotEmpty && row[0].toString().trim().isNotEmpty)
            .map((row) => row[0].toString().trim())
            .where((value) => value != '-' && value.isNotEmpty)
            .toSet()
            .toList();
      }

      return DropdownOptions(
        departments: departments,
        destinations: destinations,
      );
    } catch (e) {
      // 에러 발생 시 빈 옵션 반환 (앱은 계속 작동)
      return DropdownOptions.empty();
    }
  }

  // 마지막 행 상태 확인 (부분 채움/완전 비어있음/완전 채워짐)
  Future<Map<String, dynamic>> _getLastRowStatus() async {
    try {
      final sheetsApi = await _getSheetsApi();
      final sheetName = await _getSheetName();
      
      // 마지막 행의 B~N열 전체 읽기 (A열은 비어있음)
      final response = await sheetsApi.spreadsheets.values.get(
        _spreadsheetId,
        '$sheetName!B:N',
      );

      if (response.values == null || response.values!.isEmpty) {
        return {
          'rowNumber': 0,
          'status': 'empty', // 완전히 비어있음
          'lastRow': null,
        };
      }

      // 마지막 행 찾기 (역순으로 확인)
      // 마지막 행 기준: E열(주행 전 거리)에 값이 있고, F열(주행 후 거리)에 값이 없는 행
      // B~N열 기준: B=인덱스0, C=인덱스1, D=인덱스2, E=인덱스3, F=인덱스4
      List<dynamic>? lastRow;
      int lastRowIndex = -1;
      
      for (int i = response.values!.length - 1; i >= 0; i--) {
        final row = response.values![i];
        if (row.isEmpty) continue;
        
        // E열(주행 전 거리, 인덱스 3)과 F열(주행 후 거리, 인덱스 4) 확인
        final hasBeforeOdometer = row.length > 3 && 
            row[3].toString().trim().isNotEmpty && 
            row[3].toString().trim() != '-';
        final hasAfterOdometer = row.length > 4 && 
            row[4].toString().trim().isNotEmpty && 
            row[4].toString().trim() != '-';
        
        // E열에 값이 있고 F열에 값이 없는 행이 마지막 행
        if (hasBeforeOdometer && !hasAfterOdometer) {
          lastRow = row;
          lastRowIndex = i;
          break;
        }
        
        // F열까지 채워진 행을 만나면 그 이후는 완전히 채워진 행이므로 중단
        // (E열만 있고 F열이 없는 행을 찾는 것이 목적이므로)
        if (hasAfterOdometer) {
          // 이미 완전히 채워진 행이므로, 마지막 부분 채워진 행을 찾지 못한 것
          // 새 행을 추가해야 함
          break;
        }
      }

      if (lastRow == null || lastRowIndex == -1) {
        return {
          'rowNumber': 0,
          'status': 'empty',
          'lastRow': null,
        };
      }

      // 마지막 행의 실제 행 번호 (헤더 제외, 1-based)
      final actualRowNumber = lastRowIndex + 1;

      // 마지막 행을 찾을 때 이미 E열(주행 전)에 값이 있고 F열(주행 후)에 값이 없는 조건으로 찾았으므로
      // 이 행은 부분적으로 채워진 행임 (업데이트 대상)
      String status = 'partial';

      return {
        'rowNumber': actualRowNumber,
        'status': status,
        'lastRow': lastRow,
      };
    } catch (e) {
      // 에러 발생 시 기본값 반환 (새 행 추가)
      return {
        'rowNumber': 0,
        'status': 'empty',
        'lastRow': null,
      };
    }
  }

  // 기록 추가
  Future<bool> appendRecord(TripRecord record) async {
    try {
      final sheetsApi = await _getSheetsApi();
      final sheetName = await _getSheetName();
      
      // 시트 이름 확인
      if (sheetName.isEmpty) {
        throw Exception('시트 이름을 가져올 수 없습니다. 시트를 선택해주세요.');
      }
      
      // 데이터 검증
      final rowData = record.toSheetRow();
      if (rowData.isEmpty) {
        throw Exception('저장할 데이터가 없습니다.');
      }
      
      // 데이터 길이 확인 (14개 컬럼: A~N)
      if (rowData.length != 14) {
        print('경고: 데이터 길이가 14가 아닙니다. 실제 길이: ${rowData.length}');
      }

      // 마지막 행 상태 확인
      final lastRowStatus = await _getLastRowStatus();
      final status = lastRowStatus['status'] as String;
      final rowNumber = lastRowStatus['rowNumber'] as int;
      final lastRow = lastRowStatus['lastRow'] as List<dynamic>?;

      print('=== 스프레드시트 저장 시도 ===');
      print('시트 이름: $sheetName');
      print('마지막 행 상태: $status');
      print('마지막 행 번호: $rowNumber');
      print('데이터: $rowData');

      // 부분 채워져 있으면 업데이트, 아니면 새 행 추가
      if (status == 'partial' && rowNumber > 0) {
        // 마지막 행 업데이트 - 필요한 열만 선택적으로 업데이트
        print('기존 행 업데이트: 행 번호 $rowNumber');
        
        // 기존 행의 전체 데이터를 먼저 읽어옴 (수식 포함) - B열부터 읽기
        final existingRowResponse = await sheetsApi.spreadsheets.values.get(
          _spreadsheetId,
          '$sheetName!B$rowNumber:N$rowNumber',
          valueRenderOption: 'FORMULA', // 수식도 읽기
        );
        
        List<dynamic> mergedRow = List.filled(13, ''); // B~N = 13개 열
        if (existingRowResponse.values != null && existingRowResponse.values!.isNotEmpty) {
          final existingRow = existingRowResponse.values![0];
          // 기존 데이터 전체 복사 (수식 포함) - B열부터
          for (int i = 0; i < existingRow.length && i < 13; i++) {
            mergedRow[i] = existingRow[i];
          }
        }
        
        // 새 데이터로 빈 필드만 채우기 (수식은 보존)
        // rowData 인덱스 -> 스프레드시트 열 매핑:
        // 0=B(사용일자), 1=C(부서), 2=D(성명), 3=E(주행 전 주행거리-수식), 4=F(주행 후 주행거리), 5=G(사용거리)...
        
        for (int i = 0; i < rowData.length && i < 13; i++) {
          final existingValue = mergedRow[i].toString().trim();
          final newValue = rowData[i].toString().trim();
          
          // 기존 값이 수식인지 확인 (=로 시작하는지)
          final isFormula = existingValue.startsWith('=');
          
          // 수식이면 절대 건드리지 않음
          if (isFormula) {
            continue;
          }
          
          // 기존 값이 비어있거나 '-'이면 새 값으로 채움
          if (existingValue.isEmpty || existingValue == '-' || existingValue == 'null') {
            mergedRow[i] = newValue;
          } else if (newValue.isNotEmpty && newValue != '-' && newValue != 'null') {
            // 기존 값이 있어도 새 값이 있으면 업데이트 (덮어쓰기)
            mergedRow[i] = newValue;
          }
        }

        final updateRange = '$sheetName!B$rowNumber:N$rowNumber'; // B열부터 업데이트
        final valueRange = ValueRange(
          values: [mergedRow],
        );

        final response = await sheetsApi.spreadsheets.values.update(
          valueRange,
          _spreadsheetId,
          updateRange,
          valueInputOption: 'USER_ENTERED',
        );

        print('업데이트 응답: ${response.toJson()}');
        print('업데이트된 범위: ${response.updatedRange}');
        print('업데이트된 행 수: ${response.updatedRows}');
        print('업데이트된 열 수: ${response.updatedColumns}');

        if (response.updatedRows == null || response.updatedRows == 0) {
          throw Exception('데이터가 업데이트되지 않았습니다.');
        }

        print('=== 업데이트 성공 ===');
        return true;
      } else {
        // 새 행 추가
        final range = '$sheetName!A:N';
        print('새 행 추가: $range');
        
        final values = [rowData];
        final valueRange = ValueRange(
          values: values,
        );

        final response = await sheetsApi.spreadsheets.values.append(
          valueRange,
          _spreadsheetId,
          range,
          valueInputOption: 'USER_ENTERED',
          insertDataOption: 'INSERT_ROWS',
        );

        // 응답 확인 및 디버깅
        print('API 응답: ${response.toJson()}');
        print('업데이트된 범위: ${response.updates?.updatedRange}');
        print('업데이트된 행 수: ${response.updates?.updatedRows}');
        print('업데이트된 열 수: ${response.updates?.updatedColumns}');
        
        // 응답 확인
        if (response.updates == null) {
          throw Exception('API 응답이 없습니다. 시트 범위를 확인해주세요.');
        }

        // 저장 후 실제로 데이터가 추가되었는지 확인
        await Future.delayed(const Duration(milliseconds: 1000)); // 데이터 반영 대기
        try {
          final verifyResponse = await sheetsApi.spreadsheets.values.get(
            _spreadsheetId,
            '$sheetName!A:A',
          );
          
          // 마지막 행의 데이터 확인
          if (verifyResponse.values != null && verifyResponse.values!.isNotEmpty) {
            final lastRowData = verifyResponse.values!.last;
            print('추가된 마지막 행 데이터: $lastRowData');
          }
        } catch (e) {
          print('데이터 확인 중 에러 (무시): $e');
        }

        print('=== 저장 성공 ===');
        return true;
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('스프레드시트 저장 에러: $errorMsg');
      
      if (errorMsg.contains('400') || errorMsg.contains('INVALID_ARGUMENT')) {
        throw Exception('스프레드시트 형식 오류입니다.\n시트 이름: ${await _getSheetName()}\n범위: A:N\n상세: ${e.toString().split(':').last.trim()}');
      } else if (errorMsg.contains('403') || errorMsg.contains('PERMISSION_DENIED')) {
        throw Exception('스프레드시트 접근 권한이 없습니다.\n로그인한 계정으로 스프레드시트를 공유해주세요.');
      } else if (errorMsg.contains('404') || errorMsg.contains('NOT_FOUND')) {
        throw Exception('스프레드시트를 찾을 수 없습니다.\n스프레드시트 ID를 확인해주세요.');
      }
      throw Exception('기록 추가 실패: ${e.toString().split(':').last.trim()}');
    }
  }
}

// 인증된 HTTP 클라이언트 래퍼
class _AuthenticatedClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  _AuthenticatedClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
