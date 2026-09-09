# FastPix iOS Player - SwiftUI video player demo app (HLS, subtitles, playlists)

[![Platform: iOS](https://img.shields.io/badge/platform-iOS%2018.2%2B-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![UI: SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0071E3?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![FastPix iOS Player SDK](https://img.shields.io/badge/FastPix-iOS%20Player%20SDK%200.9.0-5D09C7)](https://github.com/FastPix/iOS-player)

A ready-to-run SwiftUI sample app showing how to integrate the [FastPix iOS Player SDK](https://github.com/FastPix/iOS-player) for HLS video playback in a SwiftUI app. It embeds the FastPix player (backed by `AVPlayerViewController`) inside SwiftUI and demonstrates subtitle rendering, audio and subtitle track switching, and playlist management, with full control over the UI and playback behavior.

**Works with:** iOS 18.2+ · SwiftUI · UIKit interop (`UIViewControllerRepresentable`) · Swift Package Manager · FastPix iOS Player SDK (`iOS-player` 0.9.0)

📖 **iOS Player docs:** https://fastpix.com/docs/ios-player/install-fastpix-ios-player &nbsp;·&nbsp; ▶️ **Player SDK:** https://github.com/FastPix/iOS-player &nbsp;·&nbsp; 🚀 **Dashboard:** https://dashboard.fastpix.com

<br />

## What this app demonstrates

This sample is a reference implementation for playing FastPix video in a SwiftUI app. It shows how to:

- **Play HLS video** - stream FastPix playback IDs through the FastPix iOS Player SDK
- **Render subtitles in SwiftUI** - draw subtitle cues in the SwiftUI layer from SDK delegate callbacks
- **Switch audio and subtitle tracks** - drive track selection through the SDK
- **Manage a playlist** - play a multi-item playlist with autoplay and looping
- **Bridge UIKit and SwiftUI** - host the player with `UIViewControllerRepresentable`

The FastPix iOS Player SDK is already integrated via Swift Package Manager, and the app ships with two working sample videos, so it plays out of the box with no configuration.

<br />

## Start here

If you are setting up this demo for the first time, follow these steps in order:

1. [Check your macOS version](#1-check-your-macos-version)
2. [Check that Xcode is installed](#2-check-that-xcode-is-installed)
3. [Check for a compatible simulator](#3-check-for-a-compatible-simulator)
4. [Clone the repository](#4-clone-the-repository)
5. [Resolve the Swift package dependency](#5-resolve-the-swift-package-dependency)
6. [Build and run the app](#6-build-and-run-the-app)
7. [Play a video and verify it works](#7-play-a-video-and-verify-it-works)

Do not skip the verification commands. If a step's check fails, fix that problem before you continue.

Unlike some FastPix demos, this app needs **no credentials and no code changes**: the SDK is already integrated via Swift Package Manager and two public sample videos are bundled, so it plays out of the box on a simulator.

<br />

## Before you begin

Make sure you have the following ready:

| Requirement | Details |
|---|---|
| **A Mac with Xcode 16.2 or later** | Install the full Xcode app from the App Store. It provides the build tools, the Swift compiler, Git, and the iOS 18.2+ SDK. The project was created with Xcode 16.2. |
| **An iOS 18.2+ simulator or device** | The project's deployment target is iOS 18.2, so you need a simulator or device running iOS 18.2 or later. |
| **A FastPix account** *(optional)* | Needed only if you want to play your own videos. The bundled sample videos require no account or credentials. |

> **Supported iOS versions:** The project targets **iOS 18.2**. Use an iOS 18.2+ simulator or device. To run on an older OS, lower `IPHONEOS_DEPLOYMENT_TARGET` in the project's **Build Settings** (verify your SDK version supports it), or see [Build fails on an older iOS version](#build-fails-on-an-older-ios-version).

<br />

## 1. Check your macOS version

The build tools run on macOS. Confirm your version:

```bash
sw_vers
```

Output is similar to:

```text
ProductName:		macOS
ProductVersion:		26.6.2
BuildVersion:		25G83
```

Use a macOS version that supports Xcode 16.2 or later. If macOS is too old, update it before you continue.

<br />

## 2. Check that Xcode is installed

This project builds with the full Xcode app. Confirm the command line points at Xcode:

```bash
xcodebuild -version
```

Expected output is similar to:

```text
Xcode 26.6
Build version 17F113
```

If instead you see `xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`, point the command line at Xcode (this needs your password):

```bash
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -license accept
```

Then run `xcodebuild -version` again. Do not continue until it prints a version.

<br />

## 3. Check for a compatible simulator

The project's deployment target is iOS 18.2, so you need a simulator (or device) running iOS 18.2 or later. List the simulators installed on your Mac:

```bash
xcrun simctl list devices available
```

Output is similar to:

```text
-- iOS 26.5 --
    iPhone 17 (...) (Shutdown)
    iPhone 17 Pro (...) (Shutdown)
```

Note a device name that appears under an `-- iOS 18.2 --` (or later) heading. You use it in [Build and run the app](#6-build-and-run-the-app). If no iOS 18.2+ runtime is listed, install one in Xcode from **Xcode > Settings > Components**, then run the command again.

<br />

## 4. Clone the repository

```bash
git clone "https://github.com/FastPix/fastpix-ios-player-swiftui-demo.git"
cd fastpix-ios-player-swiftui-demo
```

<br />

## 5. Resolve the Swift package dependency

The FastPix iOS Player SDK is already added via Swift Package Manager. Xcode resolves it automatically when you open the project, but you can resolve and verify it from the command line:

```bash
xcodebuild -project PlayerSwiftUI.xcodeproj -resolvePackageDependencies
```

The output confirms the pinned SDK version:

```text
Resolved source packages:
  FastPixPlayerSDK: https://github.com/FastPix/iOS-player.git @ 0.9.0
```

If resolution fails, see [Swift Package fails to resolve](#swift-package-fails-to-resolve).

<br />

## 6. Build and run the app

#### Option A: Using Xcode

1. Open `PlayerSwiftUI.xcodeproj` in Xcode.
2. Let Xcode finish resolving the Swift package dependency (`FastPixPlayerSDK` from `iOS-player`).
3. Select an iOS 18.2+ simulator or connected device as the run destination, then press **Run** (`⌘R`).

#### Option B: Using the command line

Replace `iPhone 17` with the device name you noted in [Check for a compatible simulator](#3-check-for-a-compatible-simulator).

```bash
xcodebuild -project PlayerSwiftUI.xcodeproj \
           -scheme PlayerSwiftUI \
           -destination "platform=iOS Simulator,name=iPhone 17" \
           build
```

A successful build ends with:

```text
** BUILD SUCCEEDED **
```

<br />

## 7. Play a video and verify it works

On launch you land on a home screen with a **FastPix Player** card labeled **Play Videos**. Tap it to open the player and begin playing the first bundled sample video. You can scrub the timeline, switch audio and subtitle tracks, see subtitle text rendered over the video, and move through the two-item playlist.

A working app confirms that:

- Xcode and the iOS 18.2+ SDK are installed.
- The `FastPixPlayerSDK` package resolved at version 0.9.0.
- The app builds, launches, and plays HLS video through the FastPix iOS Player SDK.

If playback does not start, see [Troubleshooting](#troubleshooting).

<br />

## Play your own video

To swap in your own content, replace the sample playback IDs in the app's playlist (defined in `FastPixSwiftUIPlayer.swift`, inside the view model's `playlist` array) with your own FastPix playback IDs. Each item is a `FastPixPlaylistItem`; leave `token` and `drmToken` empty for public videos, or supply a token for signed/DRM playback. To create playback IDs, see the [FastPix iOS Player install guide](https://fastpix.com/docs/ios-player/install-fastpix-ios-player).

<br />

## How the integration works

The sections below are the key integration points, mirrored by the source in `FastPixSwiftUIPlayer.swift`. They also serve as a reference for adding the FastPix player to your own SwiftUI app.

### Import the SDK and build a playlist

```swift
import FastPixPlayerSDK

//Create Playlist
let playlist: [FastPixPlaylistItem] = [
    FastPixPlaylistItem(
        playbackId: "PLAYBACK_ID",
        title: "Sample Video",
        duration: "00:00:00",
        token: "",
        drmToken: ""
    )
]
```

### Set up the player

```swift
playerViewController.addPlaylist(playlist)
playerViewController.isAutoPlayEnabled = true
playerViewController.isLoopEnabled = true

//Setup Delegates
playerViewController.subtitleTrackDelegate = coordinator
```

### Host the player in SwiftUI

Wrap the UIKit player using `UIViewControllerRepresentable`:

```swift
struct FastPixPlayerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> FastPixPlayerHostVC {
        return FastPixPlayerHostVC()
    }

    func updateUIViewController(_ uiViewController: FastPixPlayerHostVC, context: Context) {}
}
```

> In the actual source, `FastPixPlayerRepresentable` also injects a `Coordinator` and the view model and passes the playlist to `FastPixPlayerHostVC`. The snippet above is the minimal shape; see `FastPixSwiftUIPlayer.swift` for the full wiring.

### Render subtitles in SwiftUI

Handle the subtitle cue delegate callback:

```swift
func onSubtitleCueChange(information: SubtitleRenderInfo) {
    DispatchQueue.main.async {
        if information.text.isEmpty {
            self.viewModel.subtitleText = ""
            self.viewModel.showSubtitle = false
        } else {
            self.viewModel.subtitleText = information.text
            self.viewModel.showSubtitle = true
        }
    }
}
```

Then draw the cue text over the video:

```swift
if viewModel.showSubtitle {
    Text(viewModel.subtitleText)
        .foregroundColor(.white)
        .font(.system(size: 16, weight: .medium))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(6)
}
```

<br />

## Architecture overview

### App layer (SwiftUI)

Handles UI rendering, state management, the subtitle overlay, navigation, hosting `AVPlayerViewController`, and delegate communication.

### SDK layer (FastPix)

Handles the playback engine, audio and subtitle parsing, skip segments, buffering and playback states, and seek-preview thumbnails.

### Responsibilities

The **SDK** handles video playback, audio track switching, subtitle parsing, skip-segment logic, playback speed, buffering state, and thumbnail previews. The **app layer** handles UI controls (buttons, sliders), subtitle rendering UI, the playlist UI, the audio/subtitle settings UI, and custom overlays.

Subtitles are rendered in the SwiftUI layer using SDK callbacks, and audio and subtitle data is controlled through SDK delegates.

<br />

## Troubleshooting

### Swift Package fails to resolve
Ensure Xcode can reach GitHub, then use **File → Packages → Reset Package Caches** followed by **Resolve Package Versions**. The dependency is `FastPixPlayerSDK` from `https://github.com/FastPix/iOS-player` (pinned to 0.9.0).

### Build fails on an older iOS version
The project targets iOS 18.2. Use an iOS 18.2+ simulator/device, or lower `IPHONEOS_DEPLOYMENT_TARGET` in the project settings if your SDK version supports it.

### Video does not play
Confirm the playback ID is valid and the video's status is ready in your [FastPix Dashboard](https://dashboard.fastpix.com), and check network connectivity. The bundled samples are public and require no token.

<br />

## Which FastPix repo do I need?

This demo shows the iOS player in SwiftUI. For the underlying SDK and other platforms:

| I want to... | Repo |
|---|---|
| Use the FastPix iOS Player SDK directly (the SDK this demo uses) | [iOS-player](https://github.com/FastPix/iOS-player) |
| See a UIKit / reels-style iOS player demo | [demo-ios-reel-app](https://github.com/FastPix/demo-ios-reel-app) |
| Play FastPix video on the web | [web-player-component](https://github.com/FastPix/web-player-component) |
| Add playback QoE analytics for AVPlayer (iOS / tvOS) | [iOS-data-avplayer-sdk](https://github.com/FastPix/iOS-data-avplayer-sdk) |
| Add resumable uploads to an iOS app | [iOS-Uploads](https://github.com/FastPix/iOS-Uploads) |

Browse everything in the [FastPix organization](https://github.com/orgs/FastPix/repositories).

<br />

## FAQ

**What does this app do?**
It plays FastPix HLS video in a SwiftUI app using the FastPix iOS Player SDK, with subtitles, track switching, and a playlist. See [What this app demonstrates](#what-this-app-demonstrates).

**Do I need a FastPix account to run it?**
No. It ships with two public sample videos and plays out of the box. You only need an account to play your own videos. See [Play your own video](#play-your-own-video).

**How is the SDK added?**
Via Swift Package Manager - the package `iOS-player` (module `FastPixPlayerSDK`) is already pinned to version 0.9.0 in the project.

**How do I play my own video?**
Replace the sample playback IDs in the playlist in `FastPixSwiftUIPlayer.swift` with your own. See [Play your own video](#play-your-own-video).

**How are subtitles rendered?**
The SDK emits subtitle cues via a delegate callback, and the app draws them in the SwiftUI layer. See [Render subtitles in SwiftUI](#render-subtitles-in-swiftui).

**Which iOS version is required?**
The project targets iOS 18.2 and was built with Xcode 16.2. See [Before you begin](#before-you-begin).

**How do I add the FastPix player to my own app?**
Follow the [install guide](https://fastpix.com/docs/ios-player/install-fastpix-ios-player) and use the [iOS-player](https://github.com/FastPix/iOS-player) SDK. See [How the integration works](#how-the-integration-works).

<br />

## Documentation

- **Install the FastPix iOS player**: [fastpix.com/docs/ios-player/install-fastpix-ios-player](https://fastpix.com/docs/ios-player/install-fastpix-ios-player)
- **Manage playlists**: [fastpix.com/docs/ios-player/manage-playlists](https://fastpix.com/docs/ios-player/manage-playlists)
- **Switch subtitle tracks**: [fastpix.com/docs/ios-player/switch-subtitle-tracks](https://fastpix.com/docs/ios-player/switch-subtitle-tracks)
- **Switch audio tracks**: [fastpix.com/docs/ios-player/switch-audio-tracks](https://fastpix.com/docs/ios-player/switch-audio-tracks)
- **Complete integration example**: [fastpix.com/docs/ios-player/complete-integration-example](https://fastpix.com/docs/ios-player/complete-integration-example)
- **FastPix iOS Player SDK repo**: [github.com/FastPix/iOS-player](https://github.com/FastPix/iOS-player)

<br />
