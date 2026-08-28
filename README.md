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

## Prerequisites

Before you start, make sure you have:

- A **Mac with Xcode 16.2 or later** (the project was created with Xcode 16.2).
- An **iOS 18.2+ simulator or device** - the project's deployment target is iOS 18.2. To run on an older OS, lower `IPHONEOS_DEPLOYMENT_TARGET` in the project settings (verify your SDK version supports it).
- A **FastPix account** only if you want to play your own videos. The bundled sample videos need no account or credentials.

<br />

## Run the demo

The FastPix iOS Player SDK is already added via Swift Package Manager and the app includes two public sample videos, so no credentials or code changes are needed.

Clone the repository:

```bash
git clone "https://github.com/FastPix/fastpix-ios-player-swiftui-demo.git"
cd fastpix-ios-player-swiftui-demo
```

Then:

1. Open `PlayerSwiftUI.xcodeproj` in Xcode.
2. Let Xcode resolve the Swift Package dependency (`FastPixPlayerSDK` from `iOS-player`).
3. Select a simulator or a connected device (iOS 18.2+) and press **Run** (`⌘R`).
4. Tap **Play Videos** on the home screen to open the player.

<br />

## Verify it works

On launch you land on a home screen with a **Play Videos** card. Tapping it opens the player and begins playing the first bundled sample video. You can scrub the timeline, switch audio and subtitle tracks, see subtitle text rendered over the video, and move through the two-item playlist. If playback does not start, see [Troubleshooting](#troubleshooting).

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
The project targets iOS 18.2 and was built with Xcode 16.2. See [Prerequisites](#prerequisites).

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
