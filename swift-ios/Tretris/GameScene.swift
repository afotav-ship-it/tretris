import SpriteKit
import UIKit

// MARK: - Game Scene

class GameScene: SKScene {
    weak var gameController: GameController?
    
    // Grid
    var grid: [[UIColor?]] = []
    
    // Nodes
    private var gridNode: SKNode!
    private var blockNodes: [SKSpriteNode] = []
    private var ghostNodes: [SKSpriteNode] = []
    private var gridCellNodes: [[SKSpriteNode]] = []
    
    // Visual constants
    private var cellSize: CGFloat = 20
    private var gridOrigin: CGPoint = .zero
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupGrid()
    }
    
    private func setupGrid() {
        // Calculate cell size based on screen
        let availableWidth = size.width - 20
        let availableHeight = size.height * 0.6  // Leave room for UI
        
        let cellWidth = availableWidth / CGFloat(GameConstants.gridWidth)
        let cellHeight = availableHeight / CGFloat(GameConstants.gridHeight)
        cellSize = min(cellWidth, cellHeight)
        
        let gridWidth = cellSize * CGFloat(GameConstants.gridWidth)
        let gridHeight = cellSize * CGFloat(GameConstants.gridHeight)
        
        gridOrigin = CGPoint(
            x: (size.width - gridWidth) / 2,
            y: size.height * 0.35  // Position grid in upper portion
        )
        
        // Create grid background
        gridNode = SKNode()
        gridNode.position = gridOrigin
        addChild(gridNode)
        
        // Create background
        let bgRect = SKShapeNode(rect: CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight))
        bgRect.fillColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        bgRect.strokeColor = .gray
        gridNode.addChild(bgRect)
        
        // Create grid lines
        for x in 0...GameConstants.gridWidth {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(x) * cellSize, y: 0))
            path.addLine(to: CGPoint(x: CGFloat(x) * cellSize, y: gridHeight))
            line.path = path
            line.strokeColor = UIColor(white: 0.3, alpha: 1)
            line.lineWidth = 0.5
            gridNode.addChild(line)
        }
        
        for y in 0...GameConstants.gridHeight {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: CGFloat(y) * cellSize))
            path.addLine(to: CGPoint(x: gridWidth, y: CGFloat(y) * cellSize))
            line.path = path
            line.strokeColor = UIColor(white: 0.3, alpha: 1)
            line.lineWidth = 0.5
            gridNode.addChild(line)
        }
        
        // Initialize grid cell nodes
        gridCellNodes = Array(repeating: Array(repeating: SKSpriteNode(), count: GameConstants.gridWidth), count: GameConstants.gridHeight)
        
        for y in 0..<GameConstants.gridHeight {
            for x in 0..<GameConstants.gridWidth {
                let node = SKSpriteNode(color: .clear, size: CGSize(width: cellSize - 2, height: cellSize - 2))
                node.anchorPoint = .zero
                node.position = CGPoint(x: CGFloat(x) * cellSize + 1, y: CGFloat(GameConstants.gridHeight - 1 - y) * cellSize + 1)
                gridNode.addChild(node)
                gridCellNodes[y][x] = node
            }
        }
        
        // Initialize grid data
        grid = Array(repeating: Array(repeating: nil, count: GameConstants.gridWidth), count: GameConstants.gridHeight)
    }
    
    func updateDisplay(currentBlock: Block?, grid: [[UIColor?]]) {
        self.grid = grid
        
        // Don't update if grid cells haven't been set up yet
        guard gridCellNodes.count == GameConstants.gridHeight,
              let firstRow = gridCellNodes.first,
              firstRow.count == GameConstants.gridWidth else {
            return
        }
        
        // Update grid cells
        for y in 0..<GameConstants.gridHeight {
            for x in 0..<GameConstants.gridWidth {
                guard y < grid.count, x < grid[y].count else { continue }
                if let color = grid[y][x] {
                    gridCellNodes[y][x].color = color
                    gridCellNodes[y][x].isHidden = false
                } else {
                    gridCellNodes[y][x].isHidden = true
                }
            }
        }
        
        // Clear old block nodes
        for node in blockNodes {
            node.removeFromParent()
        }
        blockNodes.removeAll()
        
        for node in ghostNodes {
            node.removeFromParent()
        }
        ghostNodes.removeAll()
        
        // Draw current block
        if let block = currentBlock {
            // Draw ghost first
            if let ghost = createGhost(for: block, grid: grid) {
                for (row, col) in getBlockCells(block: ghost) {
                    let node = SKSpriteNode(color: .clear, size: CGSize(width: cellSize - 2, height: cellSize - 2))
                    node.anchorPoint = .zero
                    let screenY = GameConstants.gridHeight - 1 - (ghost.y + row)
                    node.position = CGPoint(x: CGFloat(ghost.x + col) * cellSize + 1, y: CGFloat(screenY) * cellSize + 1)
                    
                    // Create border only - safely get RGB components
                    var red: CGFloat = 0.5, green: CGFloat = 0.5, blue: CGFloat = 0.5, alpha: CGFloat = 1
                    block.color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    
                    let border = SKShapeNode(rect: CGRect(x: 0, y: 0, width: cellSize - 4, height: cellSize - 4))
                    border.strokeColor = UIColor(red: red / 3, green: green / 3, blue: blue / 3, alpha: 1)
                    border.fillColor = .clear
                    border.lineWidth = 2
                    node.addChild(border)
                    
                    gridNode.addChild(node)
                    ghostNodes.append(node)
                }
            }
            
            // Draw actual block
            for (row, col) in getBlockCells(block: block) {
                let node = SKSpriteNode(color: block.color, size: CGSize(width: cellSize - 2, height: cellSize - 2))
                node.anchorPoint = .zero
                let screenY = GameConstants.gridHeight - 1 - (block.y + row)
                node.position = CGPoint(x: CGFloat(block.x + col) * cellSize + 1, y: CGFloat(screenY) * cellSize + 1)
                gridNode.addChild(node)
                blockNodes.append(node)
            }
        }
    }
    
    private func getBlockCells(block: Block) -> [(row: Int, col: Int)] {
        var cells: [(Int, Int)] = []
        guard !block.shape.isEmpty else { return cells }
        
        for row in 0..<block.shape.count {
            guard row < block.shape.count else { continue }
            let rowData = block.shape[row]
            for col in 0..<rowData.count {
                if rowData[col] != 0 {
                    cells.append((row, col))
                }
            }
        }
        return cells
    }
    
    private func createGhost(for block: Block, grid: [[UIColor?]]) -> Block? {
        let ghost = block.copy()
        let delta = block.direction.delta
        
        while isValidPosition(block: ghost, grid: grid, offsetX: delta.dx, offsetY: delta.dy) {
            ghost.x += delta.dx
            ghost.y += delta.dy
        }
        
        return ghost
    }
    
    private func isValidPosition(block: Block, grid: [[UIColor?]], offsetX: Int = 0, offsetY: Int = 0) -> Bool {
        guard !block.shape.isEmpty else { return false }
        
        for row in 0..<block.shape.count {
            guard row < block.shape.count else { continue }
            for col in 0..<block.shape[row].count {
                if block.shape[row][col] != 0 {
                    let newX = block.x + col + offsetX
                    let newY = block.y + row + offsetY
                    
                    if newX < 0 || newX >= GameConstants.gridWidth { return false }
                    if newY < 0 || newY >= GameConstants.gridHeight { return false }
                    if newY < grid.count && newX < grid[newY].count {
                        if grid[newY][newX] != nil { return false }
                    }
                }
            }
        }
        return true
    }
}
