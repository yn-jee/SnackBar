//
//  SudokuStorage.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

enum SudokuDifficulty: String, CaseIterable {
    case easy, normal, hard
}

class SudokuStorage {
    static let shared = SudokuStorage()

    private let successKey = "sudokuSuccessCount"
    private let giveUpKey = "sudokuGiveUpCount"
    
    var successCount: Int {
        get { UserDefaults.standard.integer(forKey: successKey) }
        set { UserDefaults.standard.set(newValue, forKey: successKey) }
    }

    var giveUpCount: Int {
        get { UserDefaults.standard.integer(forKey: giveUpKey) }
        set { UserDefaults.standard.set(newValue, forKey: giveUpKey) }
    }

    func recordSuccess() {
        successCount += 1
    }

    func recordGiveUp() {
        giveUpCount += 1
    }
    
    private let difficultyKey = "sudokuDifficulty"

    var difficulty: SudokuDifficulty {
        get {
            let raw = UserDefaults.standard.string(forKey: difficultyKey) ?? "normal"
            return SudokuDifficulty(rawValue: raw) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: difficultyKey)
        }
    }
}
