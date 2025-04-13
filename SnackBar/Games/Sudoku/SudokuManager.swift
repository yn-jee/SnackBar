//
//  SudokuManager.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

final class SudokuManager: ObservableObject {
    static let shared = SudokuManager()
    
    @Published var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @Published var solution: [[Int]] = []
    @Published var selectedCell: (row: Int, col: Int)? = nil
    @Published var fixedCells: Set<String> = [] // 고정 숫자 (퍼즐 문제 셀)

    private init() {
        generateNewPuzzle()
    }
    
    func generateNewPuzzle() {
        let difficulty = SudokuStorage.shared.difficulty
        print("선택된 난이도: \(difficulty)")

        let puzzle: [[Int]]

        switch difficulty {
        case .easy:
            puzzle = [
                [5, 3, 0, 0, 7, 0, 0, 0, 0],
                [6, 0, 0, 1, 9, 5, 0, 0, 0],
                [0, 9, 8, 0, 0, 0, 0, 6, 0],
                [8, 0, 0, 0, 6, 0, 0, 0, 3],
                [4, 0, 0, 8, 0, 3, 0, 0, 1],
                [7, 0, 0, 0, 2, 0, 0, 0, 6],
                [0, 6, 0, 0, 0, 0, 2, 8, 0],
                [0, 0, 0, 4, 1, 9, 0, 0, 5],
                [0, 0, 0, 0, 8, 0, 0, 7, 9]
            ]
        case .normal:
            puzzle = [
                [0, 0, 0, 0, 0, 0, 0, 1, 2],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [3, 0, 0, 5, 0, 8, 0, 0, 0],
                [0, 5, 0, 1, 0, 0, 0, 0, 0],
                [9, 0, 0, 0, 0, 0, 0, 0, 5],
                [0, 0, 0, 0, 0, 9, 0, 6, 0],
                [0, 0, 0, 7, 0, 2, 0, 0, 3],
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [6, 2, 0, 0, 0, 0, 0, 0, 0]
            ]
        case .hard:
            puzzle = [
                [0, 0, 0, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 3, 0, 0, 0, 0, 0],
                [0, 0, 1, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 6],
                [0, 0, 0, 0, 0, 0, 3, 0, 0],
                [5, 0, 0, 0, 9, 0, 0, 0, 0],
                [6, 0, 0, 0, 0, 7, 0, 0, 0],
                [0, 0, 0, 6, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 0, 0, 0]
            ]
        }

        self.board = puzzle
        self.solution = [] // 추후 실제 해답 생성기로 대체 예정
        self.fixedCells = Set()

        for row in 0..<9 {
            for col in 0..<9 {
                if puzzle[row][col] != 0 {
                    fixedCells.insert("\(row)-\(col)")
                }
            }
        }
    }

    func updateCell(row: Int, col: Int, value: Int) {
        let key = "\(row)-\(col)"
        if !fixedCells.contains(key) {
            board[row][col] = value
        }
    }

    func markSuccess() {
        SudokuStorage.shared.recordSuccess()
    }

    func markGiveUp() {
        SudokuStorage.shared.recordGiveUp()
    }
}
