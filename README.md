# FastPix iOS Player SDK – SwiftUI Sample App (Source Code Included)

This repository provides a **SwiftUI sample application with complete source code**, demonstrating how to integrate the FastPix iOS Player SDK into a SwiftUI-based iOS app.

It showcases how the FastPix Player can be embedded within SwiftUI using `AVPlayerViewController` under the hood, enabling a **fully customizable video playback experience**.

## Features

* Seamless video playback
* Subtitle and audio track switching
* Playlist management

The FastPix SDK simplifies video playback while giving developers **full control over UI, behavior, and user experience**.
# Prerequisites

## Getting Started with the Demo Application

Before running the demo, make sure you have:

1. Xcode preinstalled in your system. 

---

## Step 1: Install the Demo Application

This project already includes the FastPix iOS Player SDK integrated via **Swift Package Manager (SPM)**.

To get started:

1. Clone the repository:

```swift
git clone "https://github.com/FastPix/fastpix-ios-player-swiftui-demo.git"
```

2. Open the project in Xcode:

```swift
cd fastpix-ios-player-swiftui-demo
```

3. open PlayerSwiftUI.xcodeproj

4. Build and run the app on a simulator or real device

---

## Step 2: Basic Integration

### Import the SDK

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

### Setup Player

```swift
playerViewController.addPlaylist(playlist)
playerViewController.isAutoPlayEnabled = true
playerViewController.isLoopEnabled = true

//Setup Delegates
playerViewController.subtitleTrackDelegate = coordinator
```

## Step 3: SwiftUI Integration

Wrap the UIKit player using UIViewControllerRepresentable.

```swift
struct FastPixPlayerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> FastPixPlayerHostVC {
        return FastPixPlayerHostVC()
    }

    func updateUIViewController(_ uiViewController: FastPixPlayerHostVC, context: Context) {}
}
```

## Step 4: Subtitles Integration

Delegate Handling

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

SwiftUI Rendering

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

## Architecture Overview
### App Layer (SwiftUI)

Handles:

- UI rendering
- State management
- Subtitle overlay
- Navigation
- Hosting AVPlayerViewController
- Delegate communication

### SDK Layer (FastPix)

Handles:
- Playback engine
- Audio & subtitle parsing
- Skip segments
- Buffering & playback states
- Seek preview thumbnails

### Responsibilities

SDK Handles

- Video playback
- Audio track switching
- Subtitle parsing
- Skip segment logic
- Playback speed
- Buffering state
- Thumbnail previews

App Layer Handles

- UI controls (buttons, sliders)
- Subtitle rendering UI
- Playlist UI
- Settings UI (audio/subtitles)
- Custom overlays

## Run the Project
- Clone the repository
- Open .xcodeproj
- Run on simulator or device

### Notes
- Subtitles are rendered in the SwiftUI layer using SDK callbacks
- Audio & subtitle data is controlled via SDK delegates

## Source code reference :
 - For complete Source Code of the Demo Application check here `fastpix-ios-player-swiftui-demo`

## For Detailed documentation check below 

[Click here](https://docs.fastpix.io/docs/ios-player) for a detailed documentation on FastPix Player SDK for iOS.
