# Tretris

A Tetris-style puzzle game with procedural folk music, featuring blocks that can collapse in multiple directions.

## Features

- **Multi-directional gameplay**: Blocks can collapse in up to 4 directions (N, S, E, W)
- **Procedural folk music**: Dynamic background music generated in real-time
- **Multiple difficulty levels**: Normal, Hard, and Chaos modes
- **Cross-platform**: Python/Pygame desktop version and Godot web export for iOS/mobile

## Project Structure

```
tretris/
├── tretris.py          # Original Python/Pygame version
├── godot-ios/          # Godot 4.x web export version
│   ├── project.godot
│   ├── scripts/        # GDScript game logic
│   └── scenes/         # Game scenes
└── swift-ios/          # (Experimental) Swift/iOS native version
```

## Running the Game

### Desktop (Python)
```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install pygame

# Run
python tretris.py
```

### Web/Mobile (Godot)
The game is deployed as a PWA at: https://afotav-ship-it.github.io/tretris-game/

To build locally:
1. Open `godot-ios/` in Godot 4.x
2. Export as Web
3. Deploy to web server

## Controls

- **Swipe left/right**: Move block horizontally
- **Swipe down**: Speed up block
- **Tap**: Rotate block
- **Reverse swipe**: Also rotates block

## License

MIT
