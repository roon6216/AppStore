// 출장 체크리스트 앱 기본 테스트

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ybsj_app/screens/login_screen.dart';

void main() {
  testWidgets('로그인 화면이 정상적으로 표시되는지 확인', (WidgetTester tester) async {
    // 로그인 화면을 직접 테스트 (Firebase 초기화 없이)
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );

    // 로그인 화면의 주요 요소들이 표시되는지 확인
    expect(find.text('출장 체크리스트'), findsOneWidget);
    expect(find.text('Google로 로그인'), findsOneWidget);
  });
}
