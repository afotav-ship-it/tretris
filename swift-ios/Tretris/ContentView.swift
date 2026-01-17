import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameController = GameController()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Landscape layout: Game on left, controls on right (50/50)
                HStack(spacing: 0) {
                    // Left half: Game area
                    SpriteView(scene: gameController.scene)
                        .frame(width: geometry.size.width / 2)
                    
                    // Right half: Controls, scores, preview
                    controlPanel(geometry: geometry)
                        .frame(width: geometry.size.width / 2)
                }
                
                // Game Over overlay
                if gameController.isGameOver {
                    gameOverOverlay
                }
                
                // Pause overlay
                if gameController.isPaused && !gameController.isGameOver {
                    pauseOverlay
                }
            }
        }
    }
    
    // MARK: - Control Panel (Right Half)
    
    func controlPanel(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Score section at top
            scoreSection
            
            Divider().background(Color.gray)
            
            // Next block preview
            nextBlockSection
            
            Divider().background(Color.gray)
            
            // Game controls
            gameControls
            
            Spacer()
            
            // Action buttons at bottom
            actionButtons
        }
        .padding()
        .background(Color(white: 0.1))
    }
    
    // MARK: - Score Section
    
    var scoreSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCORE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(gameController.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("LEVEL")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(gameController.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
            }
            
            HStack {
                Text("Lines: \(gameController.linesCleared)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(gameController.playLevelName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(gameController.playLevelColor)
            }
        }
    }
    
    // MARK: - Next Block Section
    
    var nextBlockSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("NEXT")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    // Block shape preview
                    NextBlockView(block: gameController.nextBlock)
                        .frame(width: 60, height: 60)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    
                    // Direction arrow
                    VStack {
                        Text("DIR")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(gameController.nextBlock?.direction.arrow ?? "↓")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // Quick action buttons
            VStack(spacing: 8) {
                Button(action: gameController.toggleMusic) {
                    Image(systemName: gameController.musicEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .foregroundColor(gameController.musicEnabled ? .green : .red)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: gameController.togglePause) {
                    Image(systemName: gameController.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Game Controls (D-Pad + Actions)
    
    var gameControls: some View {
        HStack(spacing: 30) {
            // D-Pad for movement
            VStack(spacing: 4) {
                Button(action: { gameController.moveUp() }) {
                    Image(systemName: "chevron.up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                HStack(spacing: 4) {
                    Button(action: { gameController.moveLeft() }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    // Center spacer
                    Color.clear
                        .frame(width: 50, height: 50)
                    
                    Button(action: { gameController.moveRight() }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: { gameController.moveDown() }) {
                    Image(systemName: "chevron.down")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(width: 50, height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(.white)
            
            // Rotate + Drop buttons
            VStack(spacing: 12) {
                // Rotate buttons
                HStack(spacing: 8) {
                    Button(action: { gameController.rotateLeft() }) {
                        Image(systemName: "rotate.left")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { gameController.rotateRight() }) {
                        Image(systemName: "rotate.right")
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(Color.blue.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
                
                // Hard drop button
                Button(action: { gameController.hardDrop() }) {
                    Text("DROP")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(width: 108, height: 50)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - Action Buttons
    
    var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: gameController.cyclePlayLevel) {
                VStack(spacing: 2) {
                    Image(systemName: "speedometer")
                        .font(.title3)
                    Text("Mode")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 70, height: 50)
                .background(gameController.playLevelColor.opacity(0.7))
                .cornerRadius(8)
            }
            
            Button(action: gameController.resetGame) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                    Text("Reset")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 70, height: 50)
                .background(Color.red.opacity(0.7))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Game Over Overlay
    
    var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("GAME OVER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text("Final Score")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("\(gameController.score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                Button(action: gameController.resetGame) {
                    Text("Play Again")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Pause Overlay
    
    var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("PAUSED")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Button(action: gameController.togglePause) {
                        Text("Resume")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: gameController.cyclePlayLevel) {
                        Text("Mode: \(gameController.playLevelName)")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(gameController.playLevelColor)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Next Block View

struct NextBlockView: View {
    let block: Block?
    
    var body: some View {
        GeometryReader { geometry in
            if let block = block, !block.shape.isEmpty {
                let cols = block.shape.first?.count ?? 1
                let rows = block.shape.count
                let cellSize = min(
                    geometry.size.width / CGFloat(max(1, cols)),
                    geometry.size.height / CGFloat(max(1, rows))
                )
                
                let shapeWidth = cellSize * CGFloat(cols)
                let shapeHeight = cellSize * CGFloat(rows)
                
                let offsetX = (geometry.size.width - shapeWidth) / 2
                let offsetY = (geometry.size.height - shapeHeight) / 2
                
                Canvas { context, size in
                    for row in 0..<rows {
                        guard row < block.shape.count else { continue }
                        for col in 0..<block.shape[row].count {
                            if block.shape[row][col] != 0 {
                                let rect = CGRect(
                                    x: offsetX + CGFloat(col) * cellSize + 1,
                                    y: offsetY + CGFloat(row) * cellSize + 1,
                                    width: cellSize - 2,
                                    height: cellSize - 2
                                )
                                context.fill(Path(rect), with: .color(Color(block.color)))
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
