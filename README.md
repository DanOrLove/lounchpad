# Lunchpad

Нативный лаунчер приложений для macOS на SwiftUI. Показывает приложения из `/Applications`, помогает находить их, запускать и собирать в папки. Окно поддерживает настройку прозрачности, а интерфейс открывается в полноэкранном режиме.

**Скачать установщик:** [Lunchpad-v0.1.0.dmg](dist/Lunchpad-v0.1.0.dmg) — откройте образ и перетащите `Lunchpad.app` в `Applications`.

При первом открытии появляется короткое знакомство. Его экран показывается один раз; в нём можно назначить глобальную клавишу/сочетание и включить запуск при входе в macOS. Настройки горячей клавиши и автозапуска доступны и после знакомства.

## Возможности

- Поиск и запуск приложений из системной папки `/Applications`.
- Создание папок и перенос приложений между ними.
- Настраиваемая прозрачность окна.
- Полноэкранный запуск и анимированные переходы.
- Глобальная горячая клавиша.
- Автозапуск через macOS Service Management.

## Сборка из исходников

Требуются macOS 14 или новее, Swift 6 и Command Line Tools for Xcode. Встроенный скрипт создаёт значки нужных размеров при помощи `sips` и `iconutil`.

```sh
git clone https://github.com/DanOrLove/lounchpad.git
cd lounchpad
./build-app.sh       # dist/Lunchpad.app
./build-dmg.sh       # dist/Lunchpad-v0.1.0.dmg
# или обе команды за один раз:
./build-release.sh
```

Чтобы подписать приложение своим сертификатом Developer ID Application, укажите его точное имя при сборке:

```sh
LUNCHPAD_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-release.sh
```

macOS требует подходящую подпись для регистрации приложения как объекта входа. Для разработки без сертификата приложение и установщик всё равно соберутся, но при включении автозапуска macOS может показать ошибку Service Management. Не подписанный Developer ID образ также может потребовать ручного подтверждения при первом открытии.

## Структура проекта

- `Sources/Lunchpad/LauncherStore.swift` — состояние приложения, сканирование приложений, папки, горячая клавиша и автозапуск.
- `Sources/Lunchpad/LauncherView.swift` — основная сетка и взаимодействия.
- `Sources/Lunchpad/OnboardingView.swift` — знакомство и запись горячей клавиши.
- `Sources/Lunchpad/GlobalHotKeyManager.swift` — системная регистрация горячей клавиши.
- `Scripts/GenerateIcon.swift` — генерация иконки приложения.
- `build-app.sh`, `build-dmg.sh`, `build-release.sh` — сборка приложения и установщика.

## Участие в разработке

Изменения можно предлагать через GitHub Issues и Pull Requests. Сборка использует только SwiftPM и системные инструменты macOS; сторонние Swift-зависимости не нужны. Проект распространяется по лицензии MIT, см. [LICENSE](LICENSE).

## English

Lunchpad is a native SwiftUI application launcher for macOS. It lists apps from `/Applications`, supports search, folders, adjustable window transparency, full-screen launch, global hotkeys, and login launch configuration.

Download `dist/Lunchpad-v0.1.0.dmg`, open it, and drag `Lunchpad.app` to `Applications`. To build from source, use macOS 14+, Swift 6, and Xcode Command Line Tools, then run `./build-release.sh`. A Developer ID Application certificate is needed for macOS login-item registration. Contributions are welcome under the MIT license.
