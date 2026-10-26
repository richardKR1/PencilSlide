# PencilSlide v1.1 · Sera 아이콘판

## 무엇을 기반으로 만들었나요?

첨부한 PencilSlide_v1.1_REDOWNLOAD.zip 안의 실제 SwiftUI App.swift와 PencilTapPattern.swift를 확인하고 수정했습니다. 앞서 만든 간소화 재구성판이 아니라 원본 v1.1을 기반으로 한 독립 Xcode 프로젝트입니다. 앱 이름은 PencilSlide, 아이콘에 쓰인 글자는 영어 필기체 Sera입니다. 최소 iPadOS 16, iPad 전용, 버전 1.1 / 빌드 3입니다. 원본 Bundle ID com.pencilsuite.pencilslide를 유지합니다.

## 유지한 기능과 개선

- 사진 보관함에서 앨범/사진 직접 읽기. PDF·PPT·파일 변환이나 사진 복사 없음.
- 모든 사진, 접근 가능한 스마트 앨범 및 사용자 앨범 표시.
- 개별 복수 선택, 전체 선택, 해제, 최신순/오래된순.
- 앨범별 선택 순서 저장. 추가한 '선택 순서 편집'에서 끌어 재배열하거나 목록에서 제거.
- 사진 원본과 비율 유지. 화면에 맞춘 고화질 PhotoKit 렌더링으로 표시하며 원본을 수정/재압축하지 않음. Live Photo는 정지 사진으로 표시.
- 측면 더블탭 다음, 연속 더블탭 2회 이전. 다음으로 갔다 돌아오는 방식 대신 첫 입력을 보류.
- 간격 0.7 / 0.95(기본) / 1.25초. 4회 기능을 끄면 다음 이동 즉시 처리.
- 입력 대기 피드백, 오래된 예약 작업 무효화, 앱 비활성/설정/수동 이동 때 입력 취소.
- 자동 3/5/10/15초, 시작/일시 정지, 반복. 반복을 끄면 마지막에서 정지.
- 펜슬 판별 중, 사진 로딩 중, 설정 창, 앱 비활성 상태에서는 자동 재생 대기.
- 이전/다음 버튼과 좌우 스와이프. 화면 한 번 탭으로 버튼 표시/숨김.
- 다크 테마, 가로/세로 지원. 재생은 조작 UI를 숨긴 상태로 시작.
- 앱 상태 막대 숨김, 홈 표시기 자동 숨김 요청, 슬라이드쇼 중 자동 잠금 방지.
- 일부 사진 허용 관리, 거부 시 설정 이동, 사진 보관함 변경 관찰, iCloud/읽기 실패 안내 및 재시도.
- Sera 전용 아이콘. 독립 Xcode 프로젝트, 공유 scheme, GitHub Actions, 핵심 로직 테스트.

## 검증 상태 — 먼저 읽으세요

현재 Windows에서 프로젝트 파일 참조, 소스 포함, Info.plist, 권한 문구, 아이콘 규격, ZIP 손상 여부를 정적 검사했습니다. Windows에는 Apple SDK와 Swift 컴파일러가 없으므로 Xcode 컴파일이나 Swift 테스트 실행을 하지 않았습니다. 실제 IPA 파일도 아직 생성되지 않았습니다. 따라서 '빌드 성공'이나 '아이패드 동작 검증 완료' 상태가 아닙니다.

GitHub Actions는 실제 앱에서 쓰는 순수 Swift 펜슬/자동재생 로직에 대해 76개 결정적 검사를 실행한 다음 iPad용 앱을 컴파일하도록 구성했습니다. GitHub의 초록 체크와 실제 아이패드 검증이 필요합니다. 테스트 파일이 포함되어 있다는 것은 테스트가 이미 통과했다는 뜻이 아닙니다.

Apple API는 4회 탭 자체를 제공하지 않습니다. 두 번의 시스템 더블탭 콜백을 조합한 것입니다. 실제 Apple Pencil 2가 연속 동작에서 두 콜백을 얼마나 안정적으로 전달하는지, 딜레이/손동작/설정 조합은 iPad Air 4에서 확인해야 합니다. 설정 시간은 물리 첫 탭이 아니라 더블탭 콜백 도착 간격 기준입니다.

## 1. Windows에서 파일 풀기

1. PencilSlide-v1.1-Sera-Xcode-GitHub.zip을 다운로드.
2. 마우스 오른쪽 클릭 → 모두 압축 풀기.
3. 안쪽에 PencilSlide, PencilSlide.xcodeproj, Tests, .github, README-KO.md가 있는지 확인.
4. ZIP 자체가 아니라 이 안쪽 폴더와 파일을 GitHub에 올립니다.

## 2. GitHub 저장소 만들기 및 소스 올리기

1. https://github.com 로그인 또는 무료 가입.
2. 오른쪽 위 + → New repository.
3. Repository name: PencilSlide-Sera.
4. 무료 표준 macOS 실행기를 쓰려면 Public 선택. 소스가 공개됩니다. 개인 사진/Apple 암호/인증 코드는 올리지 마세요.
5. Add a README 켜기 → Create repository. 기본 브랜치는 main 사용.
6. Code → Add file → Upload files.
7. 압축 푼 폴더에서 PencilSlide, PencilSlide.xcodeproj, Tests, Scripts 네 폴더와 README-KO.md, BUILD-STATUS.md, DEVICE-CHECKLIST.md, ICON-NOTES.md를 끌어 넣기.
8. 업로드 후 Commit changes. 바깥 폴더 한 겹이 더 생기지 않게 합니다.

## 3. 빌드 파일 올리기

숨김 폴더 누락을 피하도록 이 파일은 직접 등록합니다.

1. Windows에서 .github → workflows → build-ipa.yml을 메모장으로 열기.
2. Ctrl+A → Ctrl+C.
3. GitHub Code → Add file → Create new file.
4. 파일 이름: .github/workflows/build-ipa.yml
5. 본문에 Ctrl+V. 첫 줄 name: Build PencilSlide Sera IPA 확인.
6. Commit changes → main 브랜치에 저장.
7. Code에서 다음 경로를 확인: PencilSlide/App.swift, PencilSlide/Info.plist, PencilSlide/Assets.xcassets, PencilSlide.xcodeproj/project.pbxproj, Tests/main.swift, .github/workflows/build-ipa.yml.

## 4. GitHub에서 빌드하고 IPA 받기

1. Actions 탭 → 필요 시 Actions 활성화.
2. Build PencilSlide Sera IPA 실행 클릭. 저장 시 자동 실행됩니다.
3. 실행이 없으면 왼쪽 작업 이름 → Run workflow → main → Run workflow.
4. 초록 체크가 될 때까지 대기. 빨간 X면 실패한 단계의 첫 error와 로그를 확인해야 합니다.
5. 성공한 실행 Summary 아래 Artifacts → PencilSlide-Sera-unsigned 클릭. GitHub 로그인 필요.
6. 다운로드한 아티팩트 ZIP을 풀기.
7. 안의 PencilSlide-Sera-unsigned.ipa를 보관. IPA 자체는 더 풀지 않습니다.
8. PencilSlide-Sera-build-logs는 진단용. 설치에 쓰는 파일이 아닙니다.

GitHub에 Apple 계정, 인증서, Team ID, 암호, Secrets를 등록할 필요가 없습니다. IPA는 서명되지 않은 상태이고 Sideloadly가 내 계정으로 서명합니다. 결과물 보관 기간은 3일이며, 매주 재서명할 때는 보관한 IPA를 재사용하면 됩니다. 공개 저장소 표준 실행기 시간은 무료이며 아티팩트 저장 용량에는 별도 한도가 있습니다.

## 5. Windows에 Sideloadly 준비

1. 공식 https://sideloadly.io/ 접속. 유사 이름의 다른 도메인을 사용하지 마세요.
2. Windows에 맞는 Sideloadly 설치. 일반적인 64비트 PC는 64비트판.
3. 공식 페이지가 안내하는 웹 설치판 iTunes와 iCloud 설치. 현재 공식 안내는 Microsoft Store판을 제거하고 웹 설치판을 사용하라고 안내합니다.
4. Windows 재시작 후 Sideloadly 실행.
5. 데이터 전송 가능한 USB 케이블로 iPad 연결.
6. iPad 잠금 해제 → 이 컴퓨터를 신뢰 → 신뢰 → iPad 암호.
7. iTunes와 Sideloadly에서 iPad가 인식되는지 확인.

## 6. IPA 서명 및 설치

1. PencilSlide-Sera-unsigned.ipa를 Sideloadly의 IPA 영역으로 끌어 놓기.
2. 기기 목록에서 iPad 선택.
3. Apple ID/Apple Account에 본인 무료 Apple 계정 입력.
4. 첫 설치는 고급 옵션 기본값 사용. 트윅/Inject dylib는 불필요합니다.
5. Start → 요청 시 로컬 Sideloadly 창에 암호와 2단계 인증 코드 입력.
6. 성공/Done 표시와 iPad 홈 화면 아이콘 확인.
7. 암호와 인증 코드는 GitHub나 채팅에 입력하지 마세요.

## 7. iPad에서 실행 허용

1. 신뢰하지 않는 개발자가 나오면 설정 → 일반 → VPN 및 기기 관리 → 개발자 앱의 본인 계정 → 신뢰.
2. 개발자 모드 요구 시 설정 → 개인정보 보호 및 보안 → 개발자 모드 켜기 → 재시동 → 켜기 재확인.
3. 개발자 모드가 안 보이면 먼저 설치 시도 후 재시동하고 확인. 계속 없으면 iPadOS 버전과 정확한 오류를 확인해야 합니다. 모든 기기 상태에서 Windows만으로 해결된다고 검증하지 않았습니다.
4. 홈 화면에서 Sera 필기체 아이콘의 PencilSlide 실행.

## 8. 앱 사용

1. 사진 보관함 연결. 전체 앨범을 보려면 전체 접근 허용. 일부 접근이면 허용 사진만 보이고 앨범이 제한됩니다.
2. 앨범 선택 → 사진을 원하는 순서대로 탭. 선택 번호가 표시되고 바로 저장됩니다.
3. 선택 순서 편집 → 오른쪽 손잡이를 끌어 재배열 → 완료. 아무것도 선택하지 않으면 앨범 전체 재생.
4. 자동 넘김 간격과 반복 설정 → 슬라이드쇼 시작.
5. 재생 중 화면 한 번 탭 → 닫기, 재생/정지, 옵션, 이전/다음 버튼 표시. 다시 탭하면 숨김.
6. Apple Pencil 2 몸통을 두 번 탭 → 기본 0.95초 대기 후 다음. 화면을 펜으로 두 번 찍는 동작이 아닙니다.
7. 대기 중 몸통을 다시 두 번 탭 → 이전 사진만 표시.
8. 너무 빠른 네 번 두드리기로 인식이 잘 안 되면 두 번+두 번을 조금 분리하고 옵션에서 1.25초를 선택해 테스트.
9. 4회 탭 기능을 끄면 더블탭으로 즉시 다음 사진.
10. 사진 로딩 실패 시 화면의 다시 시도. iCloud 사진이면 인터넷 필요.

## 9. 상단 시간/배터리 막대와 전체 화면

앱과 슬라이드쇼 루트에 상태 막대 숨김을 적용했고 시작 Info.plist에도 상태 막대 숨김을 설정했습니다. 재생은 조작 UI가 없는 화면으로 시작합니다. 홈 표시기는 자동 숨김을 요청합니다.

iPadOS가 소유한 알림 센터, 제어 센터, 멀티태스킹 메뉴, 메뉴 막대, 윈도우 제어 항목은 앱이 영구 제거할 수 없습니다. 홈 표시기도 터치하면 다시 보일 수 있습니다. iPadOS 26 이후 UIRequiresFullScreen만으로 창 모드를 강제 차단할 수는 없습니다.

창 형태로 실행된다면 앱 상단 윈도우 제어 항목의 확대/축소 버튼으로 전체 화면으로 전환한 뒤 확인하세요. 전체 화면에서도 화면 상단을 쓸어내리면 시스템 메뉴가 나타날 수 있습니다. 이는 앱의 사진 조작 UI와 별개입니다. 정상 전체 화면에서 시간/배터리 표시가 계속 남는지는 실기기에서 검증해야 합니다.

## 10. 7일마다 갱신

무료 Apple 계정으로 서명한 앱은 7일간 유효합니다. 만료 전 USB 연결 → 같은 IPA, 같은 Apple 계정, 같은 Bundle ID/고급 설정으로 다시 설치. 앱을 먼저 삭제하지 마세요. 같은 설정으로 덮어 설치하면 선택 순서 등의 앱 데이터 유지가 가능하지만 원본 사진은 사진 앱에 보관하세요.

매주 GitHub 빌드는 필요 없습니다. 자동 갱신은 Sideloadly 자동 갱신 설정과 실행 중인 PC/daemon, USB 또는 설정된 Wi-Fi 연결이 필요합니다. 처음에는 USB 수동 갱신으로 확인하세요. 무료 계정은 보통 동시 3개 앱 제한이 있습니다.

## 오류가 나면

- Actions 없음: workflow 경로가 정확한지, .yml.txt가 아닌지 확인.
- 프로젝트/소스 없음: 저장소 맨 위에 PencilSlide.xcodeproj, PencilSlide, Tests가 바로 있는지 확인.
- AppleProductTypes 오류: 이번 Xcode 프로젝트 대신 예전 .swiftpm을 빌드하고 있지 않은지 확인. 이번 빌드는 그 모듈을 사용하지 않습니다.
- 빨간 X: 실패 단계와 첫 error 줄, build-logs 파일 확인. 성공하지 않았는데 IPA가 있다고 가정하지 마세요.
- Artifacts 없음: 실행 성공/완료, 로그인, 3일 보관 기한 확인.
- 기기 없음: 신뢰/잠금 해제/데이터 케이블/iTunes 인식/웹 설치판 구성요소 확인.
- 사진 앨범 없음: 사진 접근 권한과 일부 접근 여부 확인. 일부 접근에서는 모든 앨범이 보이지 않을 수 있습니다.
- 펜슬만 안 됨: Pencil 2인지, 충전/페어링/시스템 더블탭 설정/앱 전면 실행 확인. USB-C Pencil은 몸통 더블탭 미지원.

## 공식 참고 자료

- Sideloadly 다운로드: https://sideloadly.io/
- 계정 제한, 갱신, Windows 요구사항: https://sideloadly.io/faq
- GitHub 무료 실행기/저장 용량: https://docs.github.com/en/billing/concepts/product-billing/github-actions
- GitHub 결과물 다운로드: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts?tool=webui
- 개발자 모드: https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device
- iPad 전체 화면/윈도우 제어: https://support.apple.com/ko-kr/125309
- UIRequiresFullScreen의 한계: https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key

확인 기준일: 2026-10-27.
