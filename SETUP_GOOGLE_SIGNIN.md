# Google 로그인 설정 (필수)

에러 코드 10을 해결하려면 다음 단계를 완료해야 합니다.

## 1단계: SHA-1 지문 확인

명령 프롬프트에서 실행:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**SHA1** 값을 복사하세요 (예: `A1:B2:C3:D4:E5:F6:...`)

## 2단계: Google Cloud Console에서 OAuth 클라이언트 ID 생성

1. https://console.cloud.google.com/ 접속
2. 프로젝트 선택 또는 새로 만들기
3. **API 및 서비스** > **사용자 인증 정보** 클릭
4. 상단 **+ 사용자 인증 정보 만들기** > **OAuth 클라이언트 ID** 클릭
5. **애플리케이션 유형**: Android 선택
6. 입력:
   - **이름**: 출장 체크리스트 (또는 원하는 이름)
   - **패키지 이름**: `com.example.ybsj_app`
   - **SHA-1 인증서 지문**: 1단계에서 복사한 SHA1 값 붙여넣기
7. **만들기** 클릭
8. 생성된 **클라이언트 ID** 복사 (예: `123456789-abc123.apps.googleusercontent.com`)

## 3단계: AndroidManifest.xml에 클라이언트 ID 추가

`android/app/src/main/AndroidManifest.xml` 파일을 열고, 38-42번 줄의 주석을 해제하고 클라이언트 ID를 입력하세요:

```xml
<meta-data
    android:name="com.google.android.gms.auth.api.signin.google_sign_in.server_client_id"
    android:value="여기에_복사한_클라이언트_ID_입력" />
```

## 4단계: 앱 재빌드

```bash
flutter clean
flutter build apk --release
```

완료되면 Google 로그인이 정상 작동합니다!
