//
//  MainGameController.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let gameDidChange = Notification.Name("gameDidChange")
}

final class MainViewController: ObservableObject {
    static let shared = MainViewController()

    @Published var currentGame: GameType = .sudoku
    @Published var mainColor: Color = Color.accentColor
    
    var selectorHeight: CGFloat = 60
    var footerHeight: CGFloat = 22
    
    var totalHeight: CGFloat {
        selectorHeight + contentHeight + footerHeight * 2 + 10 + 2  // menu item 개수만큼 + 패딩 10 + Divider 2
    }

    private init() {
        loadLastSelectedGame()
    }

    func selectGame(_ game: GameType) {
        currentGame = game
        UserDefaults.standard.set(game.rawValue, forKey: "SelectedGame")
        print("selected: \(game)")
        NotificationCenter.default.post(name: .gameDidChange, object: game)
    }

    private func loadLastSelectedGame() {
        if let raw = UserDefaults.standard.string(forKey: "SelectedGame"),
           let game = GameType(rawValue: raw) {
            currentGame = game
        }
    }
    
    var contentWidth: CGFloat {
        switch currentGame {
        case .sudoku:
            return 380
        case .game2048:
            return 500
        default:
            return 400
        }
    }
    
    var contentHeight: CGFloat {
        switch currentGame {
        case .sudoku:
            return 420
        case .spellingNabi:
            return 420
        case .mineSweeper:
            return 420
        case .game2048:
            return 340
        default:
            return 300
        }
    }
    
    func adjustedAccentColor(brightnessAdjustment: Double) -> Color {
        let rgbColor = NSColor(Color.accentColor).usingColorSpace(.deviceRGB)!
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 밝기 조절
        let adjustedRed = max(min(red + CGFloat(brightnessAdjustment), 1.0), 0.0)
        let adjustedGreen = max(min(green + CGFloat(brightnessAdjustment), 1.0), 0.0)
        let adjustedBlue = max(min(blue + CGFloat(brightnessAdjustment), 1.0), 0.0)
        
        return Color(NSColor(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue, alpha: alpha))
    }
}
