//
//  SudokuStorage.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

enum SudokuDifficulty: String, CaseIterable {
    case debug, easy, normal, hard, expert
}

final class SudokuStorage : ObservableObject {
    static let shared = SudokuStorage()
    
    var isSolved: Bool {
        get { UserDefaults.standard.bool(forKey: "isSolved") }
        set { UserDefaults.standard.set(newValue, forKey: "isSolved") }
    }
    
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

    func recordGiveUp() {
        let current = UserDefaults.standard.integer(forKey: giveUpKey)
        UserDefaults.standard.set(current + 1, forKey: giveUpKey)
        print("포기: \(UserDefaults.standard.integer(forKey: giveUpKey))")
    }

    private let difficultyKey = "sudokuDifficulty"

    var difficulty: SudokuDifficulty {
        get {
            let raw = UserDefaults.standard.string(forKey: difficultyKey) ?? "debug"
            return SudokuDifficulty(rawValue: raw) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: difficultyKey)
        }
    }

    private let elapsedTimeKey = "sudokuElapsedSeconds"

    var elapsedSeconds: Int {
        get { UserDefaults.standard.integer(forKey: elapsedTimeKey) }
        set { UserDefaults.standard.set(newValue, forKey: elapsedTimeKey) }
    }

    private let fixedCellsKey = "sudokuFixedCells"
    private let solutionKey = "sudokuSolution"
    private let boardKey = "sudokuBoard"
    private let pencilMarksKey = "sudokuPencilMarks"

    var fixedCells: Set<String> {
        get {
            if let data = UserDefaults.standard.data(forKey: fixedCellsKey),
               let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: fixedCellsKey)
            }
        }
    }

    var solution: [[Int]] {
        get {
            if let data = UserDefaults.standard.data(forKey: solutionKey),
               let decoded = try? JSONDecoder().decode([[Int]].self, from: data) {
                return decoded
            }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: solutionKey)
            }
        }
    }

    var board: [[Int]] {
        get {
            if let data = UserDefaults.standard.data(forKey: boardKey),
               let decoded = try? JSONDecoder().decode([[Int]].self, from: data) {
                return decoded
            }
            return Array(repeating: Array(repeating: 0, count: 9), count: 9)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: boardKey)
            }
        }
    }

    var pencilMarks: [[[Bool]]] {
        get {
            if let data = UserDefaults.standard.data(forKey: pencilMarksKey),
               let decoded = try? JSONDecoder().decode([[[Bool]]].self, from: data) {
                return decoded
            }
            return Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: pencilMarksKey)
            }
        }
    }
    
    private let difficultySuccessPrefix = "sudokuSuccess_"

    func successCount(for difficulty: SudokuDifficulty) -> Int {
        return UserDefaults.standard.integer(forKey: difficultySuccessPrefix + difficulty.rawValue)
    }

    func recordSuccess(for difficulty: SudokuDifficulty) {
        let key = difficultySuccessPrefix + difficulty.rawValue
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
        print("성공: \(UserDefaults.standard.integer(forKey: giveUpKey)), \(key)")
    }
}
