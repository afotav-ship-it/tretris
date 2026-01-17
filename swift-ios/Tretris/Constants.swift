import Foundation
import SwiftUI

// MARK: - Game Constants

enum GameConstants {
    static let cellSize: CGFloat = 20
    static let gridWidth: Int = 16
    static let gridHeight: Int = 16
    
    static let darkGray = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1)
    static let gray = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    
    static let blockColors: [UIColor] = [
        UIColor(red: 1, green: 0, blue: 0, alpha: 1),       // Red
        UIColor(red: 0, green: 1, blue: 0, alpha: 1),       // Green
        UIColor(red: 0, green: 0, blue: 1, alpha: 1),       // Blue
        UIColor(red: 1, green: 1, blue: 0, alpha: 1),       // Yellow
        UIColor(red: 1, green: 0, blue: 1, alpha: 1),       // Magenta
        UIColor(red: 0, green: 1, blue: 1, alpha: 1),       // Cyan
        UIColor(red: 1, green: 0.5, blue: 0, alpha: 1),     // Orange
        UIColor(red: 0.5, green: 0, blue: 1, alpha: 1),     // Purple
        UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1),   // Pink
        UIColor(red: 0.5, green: 1, blue: 0.5, alpha: 1),   // Light Green
    ]
}

// MARK: - Direction

enum Direction: Int, CaseIterable {
    case up = 0
    case down = 1
    case left = 2
    case right = 3
    
    var name: String {
        switch self {
        case .up: return "UP"
        case .down: return "DOWN"
        case .left: return "LEFT"
        case .right: return "RIGHT"
        }
    }
    
    var arrow: String {
        switch self {
        case .up: return "↑"
        case .down: return "↓"
        case .left: return "←"
        case .right: return "→"
        }
    }
    
    var delta: (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }
}

// MARK: - Play Level

enum PlayLevel: Int, CaseIterable {
    case normal = 0
    case advanced = 1
    case boulder = 2
    
    var name: String {
        switch self {
        case .normal: return "NORMAL"
        case .advanced: return "ADVANCED"
        case .boulder: return "BOULDER"
        }
    }
    
    var color: Color {
        switch self {
        case .normal: return Color(red: 0.4, green: 1, blue: 0.4)
        case .advanced: return Color(red: 1, green: 1, blue: 0.4)
        case .boulder: return Color(red: 1, green: 0.4, blue: 0.4)
        }
    }
    
    var blockParams: (minCells: Int, maxCells: Int, minSize: Int?, maxSize: Int?) {
        switch self {
        case .normal:
            return (2, 4, nil, nil)
        case .advanced:
            return (3, 6, nil, 4)
        case .boulder:
            return (4, 9, 2, 3)
        }
    }
    
    func next() -> PlayLevel {
        let allCases = PlayLevel.allCases
        let nextIndex = (rawValue + 1) % allCases.count
        return allCases[nextIndex]
    }
}

// MARK: - Color Extensions

extension UIColor {
    func toGrayscale() -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let gray = 0.299 * red + 0.587 * green + 0.114 * blue
        let lightGray = min(1.0, max(0.55, gray * 0.5 + 0.55))
        
        return UIColor(red: lightGray, green: lightGray, blue: lightGray, alpha: alpha)
    }
    
    func brightened(by factor: CGFloat = 1.5) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return UIColor(
            red: min(1.0, red * factor),
            green: min(1.0, green * factor),
            blue: min(1.0, blue * factor),
            alpha: alpha
        )
    }
}
