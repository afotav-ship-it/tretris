# Tretris Web Build

This directory contains the HTML5/Web export of the Tretris game, built with Godot 4.3.

## Files

- `index.html` - Main game page
- `index.wasm` - WebAssembly binary containing the game engine
- `index.pck` - Packed game data and assets
- `index.js` - JavaScript loader for the Godot engine
- `index.service.worker.js` - Service worker for PWA support
- `index.manifest.json` - PWA manifest
- `*.png` - Game icons for various platforms and sizes

## Running Locally

You must serve these files through an HTTP server (not directly via `file://` protocol) due to browser security restrictions with WebAssembly and service workers.

### Using Python:
```bash
python3 -m http.server 8000
# Then open http://localhost:8000/index.html
```

### Using Node.js (with npx):
```bash
npx serve .
```

### Using PHP:
```bash
php -S localhost:8000
```

## Browser Requirements

### Supported Browsers:
- **Chrome/Edge**: Version 90+ (recommended)
- **Firefox**: Version 88+
- **Safari**: Version 14.1+
- **Opera**: Version 76+

### Required Features:
- WebAssembly (WASM) support
- WebGL 2.0 or WebGL 1.0 with extensions
- JavaScript ES6+
- Service Workers (for PWA features)

## Performance

- Total bundle size: ~35 MB
- Initial load time: Varies by connection (typically 5-15 seconds on broadband)
- The game uses Progressive Web App (PWA) technology, allowing it to be installed and work offline after the first load

## Screen Sizes

The game is designed to be responsive and works on:
- Desktop browsers (1280x720 and larger)
- Tablet devices (landscape and portrait)
- Mobile devices (touch controls enabled)

## Deployment

To deploy to a web server:

1. Upload all files in this directory to your web hosting
2. Ensure your web server serves the correct MIME types:
   - `.wasm` files as `application/wasm`
   - `.pck` files as `application/octet-stream`
3. For HTTPS deployment (required for some PWA features), ensure valid SSL certificate
4. Set appropriate cache headers for optimal performance

### GitHub Pages Deployment:

This can be easily deployed to GitHub Pages:
1. Create a `gh-pages` branch or use the `docs/` folder
2. Copy all files from this directory
3. Enable GitHub Pages in repository settings
4. Access at `https://<username>.github.io/<repository>/`

## Build Information

- **Godot Version**: 4.3 stable
- **Export Template**: Web (HTML5)
- **Threading**: Disabled (for broader browser compatibility)
- **VRAM Compression**: Desktop mode enabled
- **PWA**: Enabled with offline support
