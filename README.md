### [ð Console](https://console.mytiki.com) &nbsp; â &nbsp; [ð Docs](https://docs.mytiki.com)

# TIKI SDK [Flutter] âbuild the new data economy

A package for adding TIKI's decentralized infrastructure to **Flutter** projects. Add tokenized data
ownership, consent, and rewards to your app in minutes.

For native iOS and Android projects, use:

- **ð¤ Android: [tiki-sdk-android](https://github.com/tiki/tiki-sdk-android)**
- **ð iOS: [tiki-sdk-ios](https://github.com/tiki/tiki-sdk-ios)**

### [ð¬ How to get started â](https://docs.mytiki.com/docs/tiki-sdk-flutter-getting-started)

- **[API Reference â](https://docs.mytiki.com/reference/tiki-sdk-flutter-tiki-sdk-flutter-builder)**
- **[Dart Docs â](https://pub.dev/documentation/tiki_sdk_flutter/latest/)**

#### Basic Architecture

The package builds on TIKI's core SDK
implementation (**[tiki-sdk-dart](https://github.com/tiki/tiki-sdk-dart)**) adding the following
platform-specific configurations:

- A KeyStorage (`tiki_sdk_flutter_key_storage.dart`) implementation
  using [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- Native dependencies for SQLite ([sqlite3](https://pub.dev/packages/sqlite3)
  & [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs))
- Default storage directory using [path_provider](https://pub.dev/packages/path_provider)
