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

final class MainGameController: ObservableObject {
    static let shared = MainGameController()

    @Published var currentGame: GameType = .sudoku
    
    var selectorHeight: CGFloat = 60
    var footerHeight: CGFloat = 22
    
    var totalHeight: CGFloat {
        selectorHeight + contentMinHeight + footerHeight * 2 + 10   // menu item 개수만큼 + 패딩 10
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
    
    var preferredWindowWidth: CGFloat {
        switch currentGame {
        case .sudoku:
            return 380
        case .game2048:
            return 500
        default:
            return 400
        }
    }
    
    var contentMinHeight: CGFloat {
        switch currentGame {
        case .sudoku:
            return 450
        case .game2048:
            return 340
        case .spellingNabi:
            return 300
        case .mineSweeper:
            return 320
        default:
            return 300
        }
    }
}
