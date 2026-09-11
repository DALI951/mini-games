# MiniGames

A growing hub of mini games, built by **DALI951**. One APK, five games to
start with — more get added with every version.

- **Tic Tac Toe** — beat the bot or a friend
- **Memory Match** — flip cards, find pairs
- **Simon Says** — repeat the light sequence
- **Snake** — eat, grow, don't crash
- **2048** — merge tiles to 2048

## Install

Every version ships as a signed APK on the [Releases](https://github.com/DALI951/mini-games/releases)
page. Download `Mini-Games-vX.Y.Z.apk`, open it, and allow "install from
unknown sources" when prompted. Updates install over the old version (same
signing key), so your high scores survive.

## The update flow

- The app checks GitHub Releases on startup and shows a banner when a newer
  version exists.
- **Settings → Updates** lets you check manually, read the release notes,
  download the APK in-app (with progress), and launch the system installer.
- The repo must stay **public** for the anonymous releases API to work.

## Versioning & releases

Semantic versioning starting at `0.1.0` — every feature/new-game release bumps
the version in `pubspec.yaml`.

- **Push to `main`** → GitHub Actions builds the APK (and runs analyze + tests).
- **Tag `vX.Y.Z`** → the same pipeline builds, signs, and publishes the release
  with `Mini-Games-vX.Y.Z.apk` attached.

```bash
# bump version in pubspec.yaml, then:
git tag v0.2.0
git push origin main --tags
```

The `0.x` stage means new games and tweaks come fast; the version number is
the only thing to watch.

## Adding a game

1. Create `lib/games/my_game.dart` exporting a `StatefulWidget` screen.
2. Register it in `lib/models/game_info.dart` (id, title, subtitle, icon,
   color, builder) — the hub grid, settings scores list, and tests pick it up
   automatically.
3. Bump the version in `pubspec.yaml` and `lib/app_info.dart`.
4. Push; tag; done.

## Local development

The `android/` scaffold is generated inside CI — develop purely with Flutter
tooling (`flutter run`), nothing Android-specific lives in the repo.

## Credits

Built by DALI951. Signing keystore is stored as GitHub Actions secrets
(`KEYSTORE_B64` / `KEYSTORE_PASS` / `KEYSTORE_ALIAS` / `KEYSTORE_KEY_PASS`).