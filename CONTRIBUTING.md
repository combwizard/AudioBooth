# Contributing to AudioBooth

## Prerequisites

- Xcode 26+ (latest stable)
- An Apple ID (free account works for simulator builds)

## Building as a Contributor

Simulator builds work out of the box with no extra setup.

For **device builds**, create a local signing configuration.

### 1. Add your Apple ID to Xcode

Open the project in Xcode and go to **Settings → Accounts** (⌘,). Add your Apple ID if it's not already there. Select the account, then make sure there is a Team with your name listed in the Team section. If there is no team there, click **Download Manual Profiles** to generate one.

### 2. Create your Local.xcconfig

```bash
cp AudioBooth/Local.xcconfig.example AudioBooth/Local.xcconfig
```

Edit `Local.xcconfig` and update:

- **`DEVELOPMENT_TEAM`**: your Team ID (Xcode → Settings → Accounts → select your Apple ID → Team list)
- **`ORG_IDENTIFIER`**: a reverse-DNS identifier unique to you, e.g. `me.yourname`

Leave the remaining settings from the example as-is:

- **`CONTRIBUTOR_ENTITLEMENTS_SUFFIX = Contributor`** — uses stripped-down entitlements that free/personal teams can provision (no CarPlay, NFC, iCloud KV, or Watch Wi-Fi access)
- **`SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) CONTRIBUTOR_BUILD`** — disables iCloud key-value sync in contributor builds

The file is gitignored, so your local settings will never be committed.

### 3. Build

Open `AudioBooth/AudioBooth.xcodeproj` and build. Your bundle IDs, app group, and keychain access will be derived from `ORG_IDENTIFIER` automatically — no manual capability editing required.

**Contributor builds vs. production:** some features are unavailable in contributor builds because they require capabilities your personal team cannot provision:

| Feature | Contributor build |
|---------|-------------------|
| iCloud preference sync | Disabled (`CONTRIBUTOR_BUILD`) |
| CarPlay | Not entitled |
| NFC | Not entitled |
| Watch Wi-Fi info | Not entitled |

## Code Style

All Swift code should pass `swift-format`. Run:

```bash
xcrun swift-format format --in-place --recursive --parallel .
```

## Branch Naming

- `feature/<name>` for new features
- `fix/<name>` for bug fixes
