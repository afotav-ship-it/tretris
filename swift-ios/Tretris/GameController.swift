import SwiftUI
import SpriteKit
import Combine

// MARK: - Game Controller

class GameController: ObservableObject {
    // Published state for UI
    @Published var score: Int = 0
    @Published var linesCleared: Int = 0
    @Published var level: Int = 1
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
    @Published var musicEnabled: Bool = true
    @Published var effectsEnabled: Bool = true
    @Published var playLevel: PlayLevel = .normal
    @Published var numDirections: Int = 4
    
    var playLevelName: String { playLevel.name }
    var playLevelColor: Color { playLevel.color }
    var nextBlockArrow: String { nextBlock?.direction.arrow ?? "↓" }
    
    // Game state
    var grid: [[UIColor?]] = []
    var currentBlock: Block?
    @Published var nextBlock: Block?
    
    // Block parameters
    private var minCells: Int = 2
    private var maxCells: Int = 4
    private var minSize: Int?
    private var maxSize: Int?
    
    // Timing
    private var fallTimer: Timer?
    private var baseFallSpeed: TimeInterval = 0.5
    private var fallSpeed: TimeInterval = 0.5
    
    // Line clearing animation
    private var clearingLines: [(type: String, index: Int)] = []
    private var clearAnimationTimer: Timer?
    
    // Scene and audio
    let scene: GameScene
    private let audioGenerator = AudioGenerator()
    
    init() {
        scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.scaleMode = .aspectFit
        scene.gameController = self
        
        resetGame()
    }
    
    func resetGame() {
        // Stop timers
        fallTimer?.invalidate()
        clearAnimationTimer?.invalidate()
        
        // Initialize grid
        grid = Array(repeating: Array(repeating: nil, count: GameConstants.gridWidth), count: GameConstants.gridHeight)
        
        // Reset state
        score = 0
        linesCleared = 0
        level = 1
        isGameOver = false
        isPaused = false
        clearingLines = []
        
        // Set block parameters based on play level
        let params = playLevel.blockParams
        minCells = params.minCells
        maxCells = params.maxCells
        minSize = params.minSize
        maxSize = params.maxSize
        
        fallSpeed = baseFallSpeed
        
        // Generate first blocks
        nextBlock = Block(
            numDirections: numDirections,
            minCells: minCells,
            maxCells: maxCells,
            minSize: minSize,
            maxSize: maxSize
        )
        spawnNewBlock()
        
        // Start music
        if musicEnabled {
            audioGenerator.startMusic(level: level)
        }
        
        // Start fall timer
        startFallTimer()
        
        updateDisplay()
    }
    
    private func startFallTimer() {
        fallTimer?.invalidate()
        fallTimer = Timer.scheduledTimer(withTimeInterval: fallSpeed, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard !isGameOver && !isPaused && clearingLines.isEmpty else { return }
        autoMove()
    }
    
    // MARK: - Block Movement
    
    func moveLeft() {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        if block.direction == .right {
            rotateBlock(clockwise: true)
        } else {
            moveBlock(dx: -1, dy: 0)
        }
    }
    
    func moveRight() {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        if block.direction == .left {
            rotateBlock(clockwise: true)
        } else {
            moveBlock(dx: 1, dy: 0)
        }
    }
    
    func moveUp() {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        if block.direction == .down {
            rotateBlock(clockwise: true)
        } else {
            moveBlock(dx: 0, dy: -1)
        }
    }
    
    func moveDown() {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        if block.direction == .up {
            rotateBlock(clockwise: true)
        } else {
            moveBlock(dx: 0, dy: 1)
        }
    }
    
    func rotateLeft() {
        rotateBlock(clockwise: false)
    }
    
    func rotateRight() {
        rotateBlock(clockwise: true)
    }
    
    func hardDrop() {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        let delta = block.direction.delta
        
        while moveBlock(dx: delta.dx, dy: delta.dy) {
            score += 1
        }
        
        lockBlock()
    }
    
    @discardableResult
    private func moveBlock(dx: Int, dy: Int) -> Bool {
        guard let block = currentBlock else { return false }
        
        if isValidPosition(block: block, offsetX: dx, offsetY: dy) {
            block.x += dx
            block.y += dy
            updateDisplay()
            return true
        }
        return false
    }
    
    private func autoMove() {
        guard let block = currentBlock else { return }
        
        let delta = block.direction.delta
        
        if !moveBlock(dx: delta.dx, dy: delta.dy) {
            lockBlock()
        }
    }
    
    private func rotateBlock(clockwise: Bool) {
        guard let block = currentBlock, !isGameOver && !isPaused else { return }
        
        let originalShape = block.shape
        block.rotate(clockwise: clockwise)
        
        if !isValidPosition(block: block) {
            // Wall kick attempts
            let offsets = [(1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0)]
            var found = false
            
            for (dx, dy) in offsets {
                if isValidPosition(block: block, offsetX: dx, offsetY: dy) {
                    block.x += dx
                    block.y += dy
                    found = true
                    break
                }
            }
            
            if !found {
                block.shape = originalShape
            }
        }
        
        updateDisplay()
    }
    
    // MARK: - Block Spawning
    
    private func spawnNewBlock() {
        currentBlock = nextBlock
        nextBlock = Block(
            numDirections: numDirections,
            minCells: minCells,
            maxCells: maxCells,
            minSize: minSize,
            maxSize: maxSize
        )
        
        guard let block = currentBlock else { return }
        
        let spawnResult = findValidSpawnPosition(block: block)
        block.x = spawnResult.x
        block.y = spawnResult.y
        
        if !spawnResult.valid {
            isGameOver = true
            fallTimer?.invalidate()
        }
    }
    
    private func getSpawnPosition(block: Block) -> (x: Int, y: Int) {
        switch block.direction {
        case .down:
            return (GameConstants.gridWidth / 2 - block.width / 2, 0)
        case .up:
            return (GameConstants.gridWidth / 2 - block.width / 2, GameConstants.gridHeight - block.height)
        case .right:
            return (0, GameConstants.gridHeight / 2 - block.height / 2)
        case .left:
            return (GameConstants.gridWidth - block.width, GameConstants.gridHeight / 2 - block.height / 2)
        }
    }
    
    private func findValidSpawnPosition(block: Block) -> (x: Int, y: Int, valid: Bool) {
        let base = getSpawnPosition(block: block)
        
        if canSpawnBlock(block: block, x: base.x, y: base.y) {
            return (base.x, base.y, true)
        }
        
        // Search for valid position based on direction
        switch block.direction {
        case .down:
            for y in 0..<(GameConstants.gridHeight - block.height + 1) {
                for xOffset in 0..<max(GameConstants.gridWidth / 2, block.width) {
                    for x in [base.x - xOffset, base.x + xOffset] {
                        if x >= 0 && x <= GameConstants.gridWidth - block.width {
                            if canSpawnBlock(block: block, x: x, y: y) {
                                return (x, y, true)
                            }
                        }
                    }
                }
            }
            
        case .up:
            for y in stride(from: GameConstants.gridHeight - block.height, through: 0, by: -1) {
                for xOffset in 0..<max(GameConstants.gridWidth / 2, block.width) {
                    for x in [base.x - xOffset, base.x + xOffset] {
                        if x >= 0 && x <= GameConstants.gridWidth - block.width {
                            if canSpawnBlock(block: block, x: x, y: y) {
                                return (x, y, true)
                            }
                        }
                    }
                }
            }
            
        case .right:
            for x in 0..<(GameConstants.gridWidth - block.width + 1) {
                for yOffset in 0..<max(GameConstants.gridHeight / 2, block.height) {
                    for y in [base.y - yOffset, base.y + yOffset] {
                        if y >= 0 && y <= GameConstants.gridHeight - block.height {
                            if canSpawnBlock(block: block, x: x, y: y) {
                                return (x, y, true)
                            }
                        }
                    }
                }
            }
            
        case .left:
            for x in stride(from: GameConstants.gridWidth - block.width, through: 0, by: -1) {
                for yOffset in 0..<max(GameConstants.gridHeight / 2, block.height) {
                    for y in [base.y - yOffset, base.y + yOffset] {
                        if y >= 0 && y <= GameConstants.gridHeight - block.height {
                            if canSpawnBlock(block: block, x: x, y: y) {
                                return (x, y, true)
                            }
                        }
                    }
                }
            }
        }
        
        return (base.x, base.y, false)
    }
    
    private func canSpawnBlock(block: Block, x: Int, y: Int) -> Bool {
        guard !block.shape.isEmpty else { return false }
        
        for row in 0..<block.shape.count {
            guard row < block.shape.count else { continue }
            for col in 0..<block.shape[row].count {
                if block.shape[row][col] != 0 {
                    let checkX = x + col
                    let checkY = y + row
                    
                    if checkX < 0 || checkX >= GameConstants.gridWidth { return false }
                    if checkY < 0 || checkY >= GameConstants.gridHeight { return false }
                    if grid[checkY][checkX] != nil { return false }
                }
            }
        }
        return true
    }
    
    // MARK: - Position Validation
    
    private func isValidPosition(block: Block, offsetX: Int = 0, offsetY: Int = 0) -> Bool {
        guard !block.shape.isEmpty else { return false }
        
        for row in 0..<block.shape.count {
            guard row < block.shape.count else { continue }
            for col in 0..<block.shape[row].count {
                if block.shape[row][col] != 0 {
                    let newX = block.x + col + offsetX
                    let newY = block.y + row + offsetY
                    
                    if newX < 0 || newX >= GameConstants.gridWidth { return false }
                    if newY < 0 || newY >= GameConstants.gridHeight { return false }
                    if grid[newY][newX] != nil { return false }
                }
            }
        }
        return true
    }
    
    // MARK: - Block Locking
    
    private func lockBlock() {
        guard let block = currentBlock else { return }
        guard !block.shape.isEmpty else { return }
        
        let monoColor = block.color.toGrayscale()
        
        for row in 0..<block.shape.count {
            guard row < block.shape.count else { continue }
            for col in 0..<block.shape[row].count {
                if block.shape[row][col] != 0 {
                    let x = block.x + col
                    let y = block.y + row
                    if x >= 0 && x < GameConstants.gridWidth && y >= 0 && y < GameConstants.gridHeight {
                        grid[y][x] = monoColor
                    }
                }
            }
        }
        
        // Play sound
        if effectsEnabled {
            if isSolidLanding() {
                audioGenerator.playLandingSound()
            } else {
                audioGenerator.playBlopperSound()
            }
        }
        
        checkAndStartClearAnimation()
        
        if clearingLines.isEmpty {
            spawnNewBlock()
        }
        
        updateDisplay()
    }
    
    private func isSolidLanding() -> Bool {
        guard let block = currentBlock else { return true }
        guard !block.shape.isEmpty else { return true }
        
        switch block.direction {
        case .down:
            for col in 0..<block.width {
                var lowestRow = -1
                for row in 0..<block.shape.count {
                    guard row < block.shape.count, col < block.shape[row].count else { continue }
                    if block.shape[row][col] != 0 {
                        lowestRow = row
                    }
                }
                if lowestRow >= 0 {
                    let x = block.x + col
                    let y = block.y + lowestRow
                    guard x >= 0, x < GameConstants.gridWidth, y >= 0, y < GameConstants.gridHeight else { continue }
                    if y < GameConstants.gridHeight - 1 && grid[y + 1][x] == nil {
                        return false
                    }
                }
            }
            
        case .up:
            for col in 0..<block.width {
                for row in 0..<block.shape.count {
                    guard row < block.shape.count, col < block.shape[row].count else { continue }
                    if block.shape[row][col] != 0 {
                        let x = block.x + col
                        let y = block.y + row
                        guard x >= 0, x < GameConstants.gridWidth, y >= 0, y < GameConstants.gridHeight else { break }
                        if y > 0 && grid[y - 1][x] == nil {
                            return false
                        }
                        break
                    }
                }
            }
            
        case .right:
            for row in 0..<block.shape.count {
                var rightmostCol = -1
                guard row < block.shape.count else { continue }
                for col in 0..<block.shape[row].count {
                    if block.shape[row][col] != 0 {
                        rightmostCol = col
                    }
                }
                if rightmostCol >= 0 {
                    let x = block.x + rightmostCol
                    let y = block.y + row
                    guard x >= 0, x < GameConstants.gridWidth, y >= 0, y < GameConstants.gridHeight else { continue }
                    if x < GameConstants.gridWidth - 1 && grid[y][x + 1] == nil {
                        return false
                    }
                }
            }
            
        case .left:
            for row in 0..<block.shape.count {
                guard row < block.shape.count else { continue }
                for col in 0..<block.shape[row].count {
                    if block.shape[row][col] != 0 {
                        let x = block.x + col
                        let y = block.y + row
                        guard x >= 0, x < GameConstants.gridWidth, y >= 0, y < GameConstants.gridHeight else { break }
                        if x > 0 && grid[y][x - 1] == nil {
                            return false
                        }
                        break
                    }
                }
            }
        }
        
        return true
    }
    
    // MARK: - Line Clearing
    
    private func checkAndStartClearAnimation() {
        clearingLines = []
        
        // Check rows
        for y in 0..<GameConstants.gridHeight {
            if (0..<GameConstants.gridWidth).allSatisfy({ grid[y][$0] != nil }) {
                clearingLines.append(("row", y))
            }
        }
        
        // Check columns
        for x in 0..<GameConstants.gridWidth {
            if (0..<GameConstants.gridHeight).allSatisfy({ grid[$0][x] != nil }) {
                clearingLines.append(("col", x))
            }
        }
        
        if !clearingLines.isEmpty {
            brightenClearingLines()
            updateDisplay()
            
            // Schedule actual clearing
            clearAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
                self?.finishClearLines()
            }
        }
    }
    
    private func brightenClearingLines() {
        for (type, index) in clearingLines {
            if type == "row" {
                for x in 0..<GameConstants.gridWidth {
                    if let color = grid[index][x] {
                        grid[index][x] = color.brightened(by: 2.0)
                    }
                }
            } else {
                for y in 0..<GameConstants.gridHeight {
                    if let color = grid[y][index] {
                        grid[y][index] = color.brightened(by: 2.0)
                    }
                }
            }
        }
    }
    
    private func finishClearLines() {
        guard !clearingLines.isEmpty else { return }
        
        let totalLines = clearingLines.count
        
        // Clear the lines
        for (type, index) in clearingLines {
            if type == "row" {
                for x in 0..<GameConstants.gridWidth {
                    grid[index][x] = nil
                }
            } else {
                for y in 0..<GameConstants.gridHeight {
                    grid[y][index] = nil
                }
            }
        }
        
        collapseAllDirections()
        
        if totalLines > 0 {
            linesCleared += totalLines
            
            // Play explosion sound
            if effectsEnabled {
                audioGenerator.playExplosionSound(intensity: min(5, totalLines))
            }
            
            // Exponential scoring
            var points = 0
            for i in 0..<totalLines {
                points += 100 * Int(pow(2.0, Double(i)))
            }
            score += points
            
            // Level up every 5 lines
            let newLevel = (linesCleared / 5) + 1
            if newLevel > level {
                level = newLevel
                fallSpeed = baseFallSpeed * pow(0.9, Double(level - 1))
                startFallTimer()
                
                if musicEnabled {
                    audioGenerator.startMusic(level: level)
                }
            }
        }
        
        clearingLines = []
        spawnNewBlock()
        updateDisplay()
    }
    
    private func collapseAllDirections() {
        for _ in 0..<max(GameConstants.gridWidth, GameConstants.gridHeight) {
            if numDirections >= 1 { collapseDown() }
            if numDirections >= 2 { collapseUp() }
            if numDirections >= 3 { collapseLeft() }
            if numDirections >= 4 { collapseRight() }
        }
    }
    
    private func collapseDown() {
        let midY = GameConstants.gridHeight / 2
        for x in 0..<GameConstants.gridWidth {
            var cells: [UIColor] = []
            for y in midY..<GameConstants.gridHeight {
                if let color = grid[y][x] {
                    cells.append(color)
                    grid[y][x] = nil
                }
            }
            cells.reverse()
            for (i, color) in cells.enumerated() {
                grid[GameConstants.gridHeight - 1 - i][x] = color
            }
        }
    }
    
    private func collapseUp() {
        let midY = GameConstants.gridHeight / 2
        for x in 0..<GameConstants.gridWidth {
            var cells: [UIColor] = []
            for y in 0..<midY {
                if let color = grid[y][x] {
                    cells.append(color)
                    grid[y][x] = nil
                }
            }
            for (i, color) in cells.enumerated() {
                grid[i][x] = color
            }
        }
    }
    
    private func collapseRight() {
        let midX = GameConstants.gridWidth / 2
        for y in 0..<GameConstants.gridHeight {
            var cells: [UIColor] = []
            for x in midX..<GameConstants.gridWidth {
                if let color = grid[y][x] {
                    cells.append(color)
                    grid[y][x] = nil
                }
            }
            cells.reverse()
            for (i, color) in cells.enumerated() {
                grid[y][GameConstants.gridWidth - 1 - i] = color
            }
        }
    }
    
    private func collapseLeft() {
        let midX = GameConstants.gridWidth / 2
        for y in 0..<GameConstants.gridHeight {
            var cells: [UIColor] = []
            for x in 0..<midX {
                if let color = grid[y][x] {
                    cells.append(color)
                    grid[y][x] = nil
                }
            }
            for (i, color) in cells.enumerated() {
                grid[y][i] = color
            }
        }
    }
    
    // MARK: - Display Update
    
    private func updateDisplay() {
        scene.updateDisplay(currentBlock: currentBlock, grid: grid)
    }
    
    // MARK: - UI Actions
    
    func toggleMusic() {
        musicEnabled.toggle()
        if musicEnabled {
            audioGenerator.startMusic(level: level)
        } else {
            audioGenerator.stopMusic()
        }
    }
    
    func togglePause() {
        isPaused.toggle()
    }
    
    func cyclePlayLevel() {
        playLevel = playLevel.next()
        resetGame()
    }
}
