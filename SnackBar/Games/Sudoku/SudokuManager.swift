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
    @Published var isPencilMode: Bool = false
    @Published var pencilMarks: [[[Bool]]] = Array(
        repeating: Array(
            repeating: Array(repeating: false, count: 9),
            count: 9
        ),
        count: 9
    )

    private init() {
        generateNewPuzzle()
    }
    
    private func isValid(board: [[Int]], row: Int, col: Int, num: Int) -> Bool {
        for i in 0..<9 {
            if board[row][i] == num || board[i][col] == num {
                return false
            }
        }

        let startRow = row / 3 * 3
        let startCol = col / 3 * 3
        for i in 0..<3 {
            for j in 0..<3 {
                if board[startRow + i][startCol + j] == num {
                    return false
                }
            }
        }

        return true
    }

    private func solveSudoku(board: inout [[Int]]) -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row][col] == 0 {
                    for num in 1...9 {
                        if isValid(board: board, row: row, col: col, num: num) {
                            board[row][col] = num
                            if solveSudoku(board: &board) {
                                return true
                            }
                            board[row][col] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }

    private func generateSolvedBoard() -> [[Int]] {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = solveSudoku(board: &board)
        return board
    }

    func generateNewPuzzle() {
        let difficulty = SudokuStorage.shared.difficulty
        print("선택된 난이도: \(difficulty)")

        var puzzle = generateSolvedBoard()

        let removeCount: Int
        switch difficulty {
        case .easy:
            removeCount = 30
        case .normal:
            removeCount = 45
        case .hard:
            removeCount = 60
        }

        var removed = 0
        while removed < removeCount {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            if puzzle[row][col] != 0 {
                puzzle[row][col] = 0
                removed += 1
            }
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
        guard !fixedCells.contains(key) else { return }

        if board[row][col] == value {
            // If same number tapped again, treat as erase
            board[row][col] = 0
        } else {
            board[row][col] = value
        }
        // Always preserve pencil marks
    }
    
    func markSuccess() {
        SudokuStorage.shared.recordSuccess()
    }

    func markGiveUp() {
        SudokuStorage.shared.recordGiveUp()
    }
}
