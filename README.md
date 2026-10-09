# Lunchpad

Открытый лаунчер для macOS на SwiftUI. Он показывает приложения из `/Applications` на полупрозрачном системном фоне, помогает искать и раскладывать приложения по папкам. В настройках можно выбрать оттенок фонового стекла. Поддерживает глобальную горячую клавишу и запуск при входе в систему.

## Установить приложение

1. [Скачайте Lunchpad](dist/Lunchpad-v0.1.0.dmg) и откройте файл DMG.
2. Перетащите `Lunchpad.app` в папку `Applications`, затем извлеките образ DMG.
3. При первом запуске нажмите на приложение правой кнопкой в Finder, выберите **Открыть** и подтвердите запуск. Это разовое подтверждение macOS для сборки без подписи Developer ID.

При первом запуске Lunchpad покажет короткое знакомство. Там можно назначить клавишу или сочетание для открытия лаунчера и включить автозапуск. Позже эти настройки доступны в меню рядом с поиском. Нажмите на приложение, чтобы открыть его, или на значок папки, чтобы открыть папку. Дважды нажмите на название папки, чтобы переименовать её; Enter сохранит название, Esc отменит переименование. Начните печатать, чтобы найти приложение, и нажмите Enter, чтобы запустить первый результат. Esc очищает поиск, закрывает папку или прячет лаунчер.

## Собрать из исходников

Нужны macOS 14 или новее, Swift 6 и Command Line Tools for Xcode.

1. Установите Command Line Tools, если они ещё не установлены: `xcode-select --install`.
2. Склонируйте проект и перейдите в его папку:

   ```sh
   git clone https://github.com/DanOrLove/lounchpad.git
   cd lounchpad
   ```

3. Соберите приложение и установщик:

   ```sh
   ./build-release.sh
   ```

Готовое приложение появится в `dist/Lunchpad.app`, установщик — в `dist/Lunchpad-v0.1.0.dmg`. Команда `./build-app.sh` собирает только приложение, а `./build-dmg.sh` создаёт DMG из уже собранного приложения.

Для публикации с подписью Developer ID задайте имя сертификата при сборке:

```sh
LUNCHPAD_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./build-release.sh
```

Для распространения через Developer ID также нужна нотарификация Apple. Без сертификата macOS попросит вручную подтвердить первый запуск; автозапуск может потребовать разрешения в **Системные настройки → Основные → Объекты входа**.

## Разработка

- `Sources/Lunchpad/LauncherView.swift` — интерфейс, сетка приложений, папки и настройки вида.
- `Sources/Lunchpad/LauncherStore.swift` — приложения, папки и пользовательские настройки.
- `Sources/Lunchpad/OnboardingView.swift` — первое знакомство и захват горячей клавиши.
- `Sources/Lunchpad/GlobalHotKeyManager.swift` — системная горячая клавиша.
- `Scripts/GenerateIcon.swift` — генерация значка приложения.

Сторонние Swift-пакеты не используются. Предложения и исправления можно отправлять через GitHub Issues и Pull Requests. Лицензия проекта — MIT: [LICENSE](LICENSE).

## English

Lunchpad is an open-source SwiftUI launcher for macOS. It lists apps from `/Applications` over a translucent system background and supports search, folders, a customizable background tint, a global shortcut, and launch at login.

### Install

1. [Download the DMG](dist/Lunchpad-v0.1.0.dmg) and open it.
2. Drag `Lunchpad.app` to `Applications`, then eject the mounted disk image.
3. On first launch, Control-click the app in Finder, choose **Open**, and confirm. This one-time confirmation is required for the unsigned community build.

### Build

1. Install macOS 14+, Swift 6, and Xcode Command Line Tools.
2. Clone the repository: `git clone https://github.com/DanOrLove/lounchpad.git`, then `cd lounchpad`.
3. Run `./build-release.sh`. The app and DMG are written to `dist/`.

Pull Requests are welcome. The project is licensed under MIT.
