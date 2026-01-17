# Tretris - Swift iOS Version

A native iOS port of the multi-directional Tetris game with procedural folk music, built with SwiftUI and SpriteKit.

## Project Structure

```
swift-ios/
├── Tretris.xcodeproj/    # Xcode project
└── Tretris/
    ├── TretrisApp.swift      # App entry point
    ├── ContentView.swift     # Main SwiftUI view with controls
    ├── GameScene.swift       # SpriteKit game rendering
    ├── GameController.swift  # Game logic controller
    ├── Block.swift           # Block class with shape generation
    ├── Constants.swift       # Game constants, directions, play levels
    ├── AudioGenerator.swift  # AVAudioEngine procedural audio
    └── Assets.xcassets/      # App icons and colors
```

## Requirements

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS Sonoma or later (for development)

## Setup Instructions

### 1. Open in Xcode

```bash
cd swift-ios
open Tretris.xcodeproj
```

### 2. Configure Signing

1. Select the Tretris target
2. Go to Signing & Capabilities
3. Select your Team (Apple Developer account)
4. Change Bundle Identifier to something unique (e.g., `com.yourname.tretris`)

### 3. Build and Run

- **Simulator**: Select any iOS Simulator and press ⌘R
- **Device**: Connect your iPhone, select it as target, press ⌘R

## Features

### Game Mechanics
- Multi-directional block falling (1-4 directions)
- 3 play levels: Normal, Advanced, Boulder
- Ghost piece preview
- Wall kick on rotation
- Exponential scoring

### Audio
- **Procedural folk music** using AVAudioEngine
- Music evolves with game level (new elements every 5 lines)
- Sound effects: landing, blopper, explosions

### Controls
- **D-Pad**: Move blocks in any direction
- **Rotate buttons**: Rotate left/right
- **Drop button**: Hard drop
- **Pause/Music/Restart**: Top bar controls

## Architecture

### SwiftUI + SpriteKit

- **ContentView.swift**: SwiftUI wrapper with touch controls and overlays
- **GameScene.swift**: SpriteKit scene for efficient 2D rendering
- **GameController.swift**: ObservableObject managing game state

### Procedural Audio (AVAudioEngine)

The `AudioGenerator` class generates all audio in real-time:

```swift
// Generate and play music
audioGenerator.startMusic(level: currentLevel)

// Play sound effects
audioGenerator.playLandingSound()
audioGenerator.playExplosionSound(intensity: linesCleared)
```

### Block Generation

Random polyomino shapes with constraints:

```swift
let block = Block(
    numDirections: 4,    // Available movement directions
    minCells: 2,         // Minimum cells in shape
    maxCells: 4,         // Maximum cells in shape
    minSize: nil,        // Minimum bounding box
    maxSize: nil         // Maximum bounding box
)
```

## Customization

### Change Grid Size

In `Constants.swift`:
```swift
static let gridWidth: Int = 16
static let gridHeight: Int = 16
```

### Add New Play Levels

In `Constants.swift`, extend the `PlayLevel` enum:
```swift
case extreme = 3

var blockParams: (minCells: Int, maxCells: Int, minSize: Int?, maxSize: Int?) {
    switch self {
    case .extreme:
        return (6, 12, 3, 4)  // Large blocks
    ...
    }
}
```

### Modify Music

In `AudioGenerator.swift`, adjust:
- `scale` array for different notes
- `bpm` for tempo
- Level thresholds for feature unlocking

## App Store Submission

1. **Configure App Icons**: Add 1024x1024 icon to Assets.xcassets
2. **Set Version/Build**: In target settings
3. **Archive**: Product → Archive
4. **Upload**: Organizer → Distribute App → App Store Connect

## Known Limitations

- Touch controls optimized for iPhone (iPad layout may need adjustment)
- Background audio continues when app is backgrounded (may want to pause)

## Troubleshooting

### Audio Not Playing
- iOS requires user interaction before audio plays
- The first touch will enable audio

### Slow Performance
- Reduce grid size for older devices
- Disable music on low-end devices

### Signing Errors
- Ensure you have a valid Apple Developer account
- Check that Bundle ID is unique

## License

Same license as the original Python version.
