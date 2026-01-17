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
├── godot-ios/          # Godot 4.x project source
│   ├── project.godot
│   ├── scripts/        # GDScript game logic
│   └── scenes/         # Game scenes
├── web-build/          # Pre-built web export (HTML5)
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

#### Playing the Pre-built Web Version Locally

A pre-built web export is available in the `web-build/` directory. To run it:

```bash
cd web-build
python3 -m http.server 8000
# Then open http://localhost:8000/index.html in your browser
```

**Browser Requirements:**
- Chrome/Edge 90+, Firefox 88+, Safari 14.1+, or Opera 76+
- WebAssembly and WebGL support required
- Works on desktop and mobile devices

See `web-build/README.md` for detailed deployment and compatibility information.

#### Building from Source

To rebuild the web export from the Godot project:

**Requirements:**
- Godot 4.3+ (download from https://godotengine.org/download)
- Web export templates for Godot 4.3

**Steps:**
1. Download and install Godot 4.3 or newer
2. Install web export templates (Editor > Manage Export Templates)
3. Open the `godot-ios/` project in Godot
4. Go to Project > Export
5. Select "Web" preset (or add if not present)
6. Click "Export Project" and choose output location
7. Serve the exported files via HTTP server (see above)

**Command-line export:**
```bash
# Using Godot headless
godot --headless --export-release "Web" output/index.html
```

## Controls

- **Swipe left/right**: Move block horizontally
- **Swipe down**: Speed up block
- **Tap**: Rotate block
- **Reverse swipe**: Also rotates block

## License

MIT
