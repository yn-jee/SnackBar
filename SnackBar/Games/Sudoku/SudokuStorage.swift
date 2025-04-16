//
//  SudokuStorage.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

enum SudokuDifficulty: String, CaseIterable {
    case easy, normal, hard, expert
}

final class SudokuStorage : ObservableObject {
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
            let raw = UserDefaults.standard.string(forKey: difficultyKey) ?? "easy"
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
}
