# Google 로그인 설정 가이드

## 에러 코드 10 해결 방법

Google 로그인 시 "PlatformException(sign_in_failed, 10)" 에러가 발생하는 경우, 다음 설정이 필요합니다.

## 1. SHA-1 지문 확인

디버그 키스토어의 SHA-1을 확인합니다:

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

또는 Android Studio에서:
1. Gradle 탭 열기
2. `android` > `Tasks` > `android` > `signingReport` 실행
3. SHA1 값 복사

## 2. Google Cloud Console 설정

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 생성 또는 선택
3. **API 및 서비스** > **사용자 인증 정보** 이동
4. **OAuth 2.0 클라이언트 ID 만들기** 클릭
5. 애플리케이션 유형: **Android** 선택
6. 다음 정보 입력:
   - **패키지 이름**: `com.example.ybsj_app`
   - **SHA-1 인증서 지문**: 위에서 확인한 SHA-1 값 입력
7. **만들기** 클릭
8. 생성된 **클라이언트 ID** 복사 (예: `123456789-abcdefg.apps.googleusercontent.com`)

## 3. AndroidManifest.xml에 서버 클라이언트 ID 추가

`android/app/src/main/AndroidManifest.xml` 파일의 `<application>` 태그 안에 추가:

```xml
<meta-data
    android:name="com.google.android.gms.auth.api.signin.google_sign_in.server_client_id"
    android:value="여기에_복사한_클라이언트_ID_입력" />
```

## 4. Firebase 설정 (선택사항)

Firebase를 사용하려면:
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 생성
3. Android 앱 추가
4. 패키지 이름: `com.example.ybsj_app` 입력
5. `google-services.json` 파일 다운로드
6. `android/app/` 폴더에 `google-services.json` 파일 복사
7. `android/build.gradle.kts`에 다음 추가:
   ```kotlin
   plugins {
       // ... 기존 플러그인들
       id("com.google.gms.google-services")
   }
   ```
8. `android/app/build.gradle.kts`에도 추가:
   ```kotlin
   plugins {
       // ... 기존 플러그인들
       id("com.google.gms.google-services")
   }
   ```
9. `main.dart`에서 Firebase 초기화 주석 해제:
   ```dart
   await Firebase.initializeApp();
   ```

## 5. 앱 재빌드

설정 완료 후:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

## 참고사항

- 릴리스 빌드용 APK를 배포할 경우, 릴리스 키스토어의 SHA-1도 등록해야 합니다
- OAuth 클라이언트 ID는 디버그와 릴리스용으로 각각 생성할 수 있습니다
