# Windows에서 핑거벨 실행

Android 앱 3개(`핑거벨` · `핑거벨 문자` · `핑거벨 전화`)의 Flutter 진입점은 `packages/app/lib/main.dart`, `main_sms.dart`, `main_call.dart`이며 백엔드는 `backend/`(FastAPI)입니다.

- 세 앱은 같은 인증서로 서명하며 패키지 이름(`kr.fingersnap.fingerbell`, `.sms`, `.call`)·설치 이름·런처 아이콘으로 구분합니다.
- 역할(`Persona`)과 5개 기기 설정(큰 글씨·고대비·음성 안내·경고음·진동) 공유는 **핑거벨** 앱의 서명 권한 `ContentProvider`(`SharedPrefsProvider`)를 쓰며, 문자·전화 앱은 시작과 `resume`에서 읽습니다.
- 문자 알림과 걸려 오는 전화는 **세 앱 중 하나가 화면에 떠 있을 때만** 받습니다. 앱이 닫혀 있거나 화면이 꺼져 있으면 받지 못하고, 다시 열면 서버 상태로 따라잡습니다.

## 1. 백엔드 먼저 실행

IntelliJ 실행 목록에서 **FingerBell (Start Server)**를 고르고 **Run**을 누릅니다. PowerShell에서는 아래 명령을 사용합니다.

```powershell
.\run-backend.ps1
```

처음에는 `backend/.venv`를 만들고 패키지를 설치합니다. 서버는 `http://127.0.0.1:8765`에서 열리고 API 문서는 `/docs`입니다. 포트 8000은 이 PC에서 다른 프로그램(Godot MCP 서버)이 쓰고 있어 8765를 기본값으로 씁니다.

- `-Reset`: 시연 데이터를 처음 상태로 되돌리고 시작
- `-Lan`: 같은 Wi-Fi의 휴대폰에서 접속할 수 있게 모든 네트워크 주소에 엶 (방화벽 허용 필요)
- `-Port 9000`: 다른 포트

## 2. 앱 실행 (명령 한 번으로 앱 3개 설치)

### Android (PowerShell)

```powershell
.\run-android.ps1 -NoResident
```

`run-android.ps1`은 `flutter pub get`으로 의존성을 맞춘 뒤 대상 기기를 정하고(`-Device` 생략 시 아래 규칙), `adb reverse tcp:8765 tcp:8765`를 설정하며, flavor `fingerbell` · `sms` · `call`의 debug APK를 차례로 빌드(`--no-pub`)하고 `adb install -r`로 모두 설치합니다. 빌드별 시간과 설치 포함 총 시간을 출력하고 **핑거벨** 앱을 엽니다. `-NoResident`를 빼면 설치 뒤 `flutter attach`로 연결합니다(`r` 핫 리로드, `R` 핫 리스타트, `q` 디버거 종료).

`-Device`를 주지 않았을 때 기기 선택 규칙:
- 연결(인증)된 기기가 **1대**면 그 기기를 자동 선택합니다.
- 연결된 기기가 **없으면** `Medium_Phone_API_37.0`(`emulator-5554`) 에뮬레이터를 띄웁니다.
- 연결된 기기가 **2대 이상**이면 연결된 기기 id 목록을 한 줄로 출력하고 `-Device`를 고르도록 끝냅니다.

```powershell
# 기기를 직접 고를 때 (여러 기기가 연결돼 있거나 특정 에뮬레이터·실기기 지정)
.\run-android.ps1 -Device R3CX10T957B -NoResident
.\run-android.ps1 -Device emulator-5556 -Emulator '다른_AVD_이름'

# 설치 확인 (패키지 3개 확인)
adb shell pm list packages | findstr fingersnap
```

### 기기 3대 기준 시연 준비

1. IntelliJ의 **FingerBell (Start Server LAN)** 또는 `.\run-backend.ps1 -Lan`으로 백엔드를 실행합니다(포트 `8765` 방화벽 허용).
2. 루트 `.env.local.json`에 `{"FINGERBELL_API_URL": "http://<PC_IP>:8765"}`를 설정합니다(형식은 `.env.example`).
3. 어르신·보호자·시연 상대 기기 **마다 한 번씩** `.\run-android.ps1 -Device <기기ID> -NoResident`로 세 앱을 모두 설치합니다.

## 서버 주소 바꾸기

`.env.local.json`에 `FINGERBELL_API_URL`이 있으면 그 값을 씁니다 (형식은 `.env.example`). 없으면 기본 주소 `http://127.0.0.1:8765`를 씁니다. 예전 Supabase 값만 들어 있는 `.env.local.json`은 더 이상 쓰지 않으니 지워도 됩니다.

## IntelliJ IDEA · Cursor / VS Code

IntelliJ에서 저장소 루트를 열고 **Flutter**, **Dart**, **Shell Script** 플러그인을 활성화합니다. **Settings → Languages & Frameworks → Flutter**에서 Flutter SDK 루트 경로를 지정합니다. 이 프로젝트에는 Dart 3.13.5 이상을 포함하는 Flutter SDK가 필요합니다.

| 실행 구성 | 누를 버튼 | 동작 |
| --- | --- | --- |
| **FingerBell (Start Server)** | Run | 백엔드를 `127.0.0.1:8765`에서 시작 |
| **FingerBell (Start Server LAN)** | Run | 같은 Wi-Fi의 기기가 PC의 `8765` 포트에 접속할 수 있도록 백엔드 시작 |
| **FingerBell (Android)** | Run | 세 앱을 한 기기에 빌드·설치하고 핑거벨 실행 |
| **FingerBell (Debug)** | Debug | 핑거벨의 `fingerbell` flavor를 `lib/main.dart`로 시작 |
| **FingerBell SMS (Debug)** | Debug | 문자 앱의 `sms` flavor를 `lib/main_sms.dart`로 시작 |
| **FingerBell Call (Debug)** | Debug | 전화 앱의 `call` flavor를 `lib/main_call.dart`로 시작 |
| **FingerBell (Build APKs)** | Run | 기기 연결 없이 `packages/app/build/app/outputs/flutter-apk/`에 debug APK 3개 생성 |

PC에 연결된 기기에서 시연하려면 **FingerBell (Start Server)**를 실행한 뒤 **FingerBell (Android)**로 세 앱을 설치합니다. 앱의 Dart 코드를 디버깅할 때는 툴바에서 부팅된 Android 에뮬레이터 또는 USB 디버깅을 허용한 실기기를 선택하고 해당 앱의 **Debug** 구성을 사용합니다. 중단점과 Hot Reload는 이 Flutter 디버그 세션에서 사용할 수 있습니다. 실행 직전에 `adb reverse (8765)`가 연결된 Android 기기에 로컬 API 포트를 연결합니다.

여러 기기에 연결되어 있을 때 **FingerBell (Android)**의 **Script options**에 `-Device <기기ID> -NoResident`를 지정합니다. **Build APKs**와 일괄 설치는 루트 `.env.local.json`의 서버 주소를 사용합니다. 앱별 Flutter 구성에서 이 서버 주소를 쓰려면 **Additional run args**에 `--dart-define-from-file=../../.env.local.json`을 추가합니다. USB 연결에서 로컬 포트를 바꿨다면 `adb -s <기기ID> reverse tcp:<포트> tcp:<포트>`도 실행합니다.

Cursor / VS Code에서는 터미널에서 `.\run-backend.ps1`과 `.\run-android.ps1 -NoResident`를 사용합니다.

## 문제 해결

- **대상 앱이 설치되지 않았을 때 안내**: 핑거벨에서 `[문자]`·`[전화]`·`[보호자에게 전화]`·시연 버튼을 눌렀는데 `"핑거벨 문자 앱이 설치되어 있지 않아 열 수 없어요"` 또는 `"핑거벨 전화 앱이 설치되어 있지 않아 열 수 없어요"`가 뜨면 세 앱 중 일부만 설치된 상태입니다. `.\run-android.ps1 -NoResident`로 세 앱을 함께 다시 설치하세요.
- **기기가 툴바에 보이지 않을 때** `adb devices`에서 실기기가 `unauthorized`이면 기기 잠금을 풀고 USB 디버깅을 허용하세요. 에뮬레이터가 계속 `offline`이면 종료한 뒤 Android Studio의 Device Manager에서 **Cold Boot**로 시작하세요.
- **`adb reverse`가 풀렸거나 연결되지 않을 때**: USB를 다시 꽂았거나 ADB를 재시작했다면 Flutter 디버그 구성을 다시 시작하거나 `adb -s <기기ID> reverse tcp:8765 tcp:8765`를 실행하세요. Wi-Fi로 연결하는 시연에서는 `.\run-backend.ps1 -Lan`과 `.env.local.json`의 `FINGERBELL_API_URL`을 사용합니다.
- **문자·전화 앱에 역할/설정이 바로 안 보일 때**: 문자·전화 앱은 핑거벨 앱이 저장한 역할과 5개 설정을 시작과 `resume`에서 `SharedPrefsProvider`로 읽습니다. 핑거벨 앱을 지웠거나 한 번도 실행하지 않았으면 기본값(`어르신`)으로 동작합니다.

## 참고

- 실행 스크립트는 `FLUTTER_WINDOWS=false`, `FLUTTER_LINUX=false`로 Windows 데스크톱 플러그인 심볼릭 링크 준비를 건너뜁니다.
- C: 드라이브 Pub 캐시와 D: 드라이브 프로젝트 사이의 Kotlin 캐시 오류를 막기 위해 Android `gradle.properties`에 `kotlin.incremental=false`가 있습니다.
- 한글 글꼴(Noto Sans KR, OFL 1.1)은 앱에 들어 있어 오프라인에서도 같은 글꼴로 보입니다.
