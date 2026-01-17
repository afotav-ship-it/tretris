import Foundation
import UIKit

// MARK: - Block

class Block {
    var shape: [[Int]]
    var color: UIColor
    var direction: Direction
    var x: Int = 0
    var y: Int = 0
    
    var width: Int {
        shape.first?.count ?? 1
    }
    
    var height: Int {
        max(1, shape.count)
    }
    
    init(shape: [[Int]]? = nil,
         color: UIColor? = nil,
         direction: Direction? = nil,
         numDirections: Int = 4,
         minCells: Int = 2,
         maxCells: Int = 4,
         minSize: Int? = nil,
         maxSize: Int? = nil) {
        
        if let customShape = shape {
            self.shape = customShape
        } else {
            self.shape = Block.generateRandomShape(
                minCells: minCells,
                maxCells: maxCells,
                minSize: minSize,
                maxSize: maxSize
            )
        }
        
        self.color = color ?? GameConstants.blockColors.randomElement()!
        
        if let customDirection = direction {
            self.direction = customDirection
        } else {
            // Available directions based on numDirections: DOWN, UP, LEFT, RIGHT
            let directionMap: [Direction] = [.down, .up, .left, .right]
            let availableDirections = Array(directionMap.prefix(numDirections))
            self.direction = availableDirections.randomElement() ?? .down
        }
    }
    
    func rotate(clockwise: Bool = true) {
        guard !shape.isEmpty, !shape[0].isEmpty else { return }
        
        let h = shape.count
        let w = shape[0].count
        var newShape: [[Int]] = []
        
        if clockwise {
            for col in 0..<w {
                var newRow: [Int] = []
                for row in (0..<h).reversed() {
                    if row < shape.count && col < shape[row].count {
                        newRow.append(shape[row][col])
                    } else {
                        newRow.append(0)
                    }
                }
                newShape.append(newRow)
            }
        } else {
            for col in (0..<w).reversed() {
                var newRow: [Int] = []
                for row in 0..<h {
                    if row < shape.count && col < shape[row].count {
                        newRow.append(shape[row][col])
                    } else {
                        newRow.append(0)
                    }
                }
                newShape.append(newRow)
            }
        }
        
        if !newShape.isEmpty && !newShape[0].isEmpty {
            shape = newShape
        }
    }
    
    func copy() -> Block {
        let newBlock = Block(shape: shape.map { $0 }, color: color, direction: direction)
        newBlock.x = x
        newBlock.y = y
        return newBlock
    }
    
    // MARK: - Shape Generation
    
    static func generateRandomShape(
        minCells: Int = 2,
        maxCells: Int = 4,
        minSize: Int? = nil,
        maxSize: Int? = nil
    ) -> [[Int]] {
        // Determine grid size based on constraints
        var gridSize: Int
        if let max = maxSize {
            gridSize = max
        } else {
            gridSize = max(2, Int(ceil(sqrt(Double(maxCells)))) + 1)
        }
        
        if let min = minSize {
            gridSize = max(gridSize, min)
        }
        
        // Try multiple times to generate a valid shape
        for _ in 0..<20 {
            var tempShape = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
            
            // Start with one cell in the center
            let startX = gridSize / 2
            let startY = gridSize / 2
            var filled: Set<String> = ["\(startX),\(startY)"]
            tempShape[startY][startX] = 1
            
            // Pick target cell count
            let targetCells = Int.random(in: minCells...maxCells)
            
            // Grow the shape
            let maxTries = gridSize * gridSize * 10
            for _ in 0..<maxTries {
                if filled.count >= targetCells {
                    break
                }
                
                // Pick a random filled cell and try to grow
                let filledArray = Array(filled)
                let randomCell = filledArray.randomElement()!
                let parts = randomCell.split(separator: ",")
                let cx = Int(parts[0])!
                let cy = Int(parts[1])!
                
                let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)].shuffled()
                
                for (dx, dy) in directions {
                    let nx = cx + dx
                    let ny = cy + dy
                    let key = "\(nx),\(ny)"
                    
                    if nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize && !filled.contains(key) {
                        tempShape[ny][nx] = 1
                        filled.insert(key)
                        break
                    }
                }
            }
            
            // Handle min_size constraint
            if let minSizeValue = minSize {
                var minX = gridSize, maxX = 0, minY = gridSize, maxY = 0
                
                for key in filled {
                    let parts = key.split(separator: ",")
                    let x = Int(parts[0])!
                    let y = Int(parts[1])!
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
                
                var currentWidth = maxX - minX + 1
                var currentHeight = maxY - minY + 1
                
                while currentWidth < minSizeValue || currentHeight < minSizeValue {
                    var edgeCells: [(Int, Int)] = []
                    
                    for key in filled {
                        let parts = key.split(separator: ",")
                        let x = Int(parts[0])!
                        let y = Int(parts[1])!
                        
                        for (dx, dy) in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
                            let nx = x + dx
                            let ny = y + dy
                            let newKey = "\(nx),\(ny)"
                            
                            if nx >= 0 && nx < gridSize && ny >= 0 && ny < gridSize && !filled.contains(newKey) {
                                edgeCells.append((nx, ny))
                            }
                        }
                    }
                    
                    if edgeCells.isEmpty { break }
                    
                    let (nx, ny) = edgeCells.randomElement()!
                    tempShape[ny][nx] = 1
                    filled.insert("\(nx),\(ny)")
                    
                    minX = gridSize; maxX = 0; minY = gridSize; maxY = 0
                    for key in filled {
                        let parts = key.split(separator: ",")
                        let x = Int(parts[0])!
                        let y = Int(parts[1])!
                        minX = min(minX, x)
                        maxX = max(maxX, x)
                        minY = min(minY, y)
                        maxY = max(maxY, y)
                    }
                    currentWidth = maxX - minX + 1
                    currentHeight = maxY - minY + 1
                }
            }
            
            // Trim empty rows and columns
            let result = trimShape(tempShape)
            
            if result.isEmpty { continue }
            
            // Verify constraints
            let cellCount = result.reduce(0) { $0 + $1.reduce(0, +) }
            let resultHeight = result.count
            let resultWidth = result.first?.count ?? 0
            
            if cellCount < minCells || cellCount > maxCells { continue }
            if let min = minSize, (resultWidth < min || resultHeight < min) { continue }
            if let max = maxSize, (resultWidth > max || resultHeight > max) { continue }
            
            return result
        }
        
        // Fallback: simple line (always at least 1 cell)
        let fallbackCells = max(1, minCells)
        return [Array(repeating: 1, count: fallbackCells)]
    }
    
    private static func trimShape(_ shape: [[Int]]) -> [[Int]] {
        // Don't trim empty shapes
        guard !shape.isEmpty else { return [[1]] }
        
        var result = shape
        
        // Remove empty top rows
        while !result.isEmpty && result.first!.allSatisfy({ $0 == 0 }) {
            result.removeFirst()
        }
        
        // Remove empty bottom rows
        while !result.isEmpty && result.last!.allSatisfy({ $0 == 0 }) {
            result.removeLast()
        }
        
        if result.isEmpty { return [[1]] }
        
        // Remove empty left columns
        while !result.isEmpty && !result[0].isEmpty && result.allSatisfy({ $0.first == 0 }) {
            for i in 0..<result.count {
                result[i].removeFirst()
            }
        }
        
        // Remove empty right columns
        while !result.isEmpty && !result[0].isEmpty && result.allSatisfy({ $0.last == 0 }) {
            for i in 0..<result.count {
                result[i].removeLast()
            }
        }
        
        // Final safeguard
        if result.isEmpty || result[0].isEmpty {
            return [[1]]
        }
        
        return result
    }
}
