//
//  SudokuManager.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

final class SudokuManager: ObservableObject {
    static let shared = SudokuManager()
    
    @Published var isSolved: Bool = SudokuStorage.shared.isSolved
    @Published var board: [[Int]] = SudokuStorage.shared.board
    @Published var solution: [[Int]] = SudokuStorage.shared.solution
    @Published var fixedCells: Set<String> = SudokuStorage.shared.fixedCells
    @Published var isPencilMode: Bool = false
    @Published var pencilMarks: [[[Bool]]] = SudokuStorage.shared.pencilMarks
    @Published var isTimerRunning: Bool = false
    @Published var isSolutionDisplayed: Bool = false
    @Published var selectedCell: (row: Int, col: Int)? = nil
    private var startTime: Date?
    private var accumulatedSeconds: Int = SudokuStorage.shared.elapsedSeconds
    private var timer: Timer?

    private init() {
        loadFromStorage()
    }
    
    private var elapsedSecondsSnapshot: Int {
        accumulatedSeconds + (isTimerRunning && startTime != nil ? Int(Date().timeIntervalSince(startTime!)) : 0)
    }
    
    var formattedElapsedTime: String {
        let base = accumulatedSeconds
        let total = base + (isTimerRunning && startTime != nil ? Int(Date().timeIntervalSince(startTime!)) : 0)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        guard !isSolved else { return }
        isTimerRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    func pauseTimer() {
        guard isTimerRunning else {
            SudokuStorage.shared.elapsedSeconds = accumulatedSeconds
            persistCurrentGame()
            return
        }

        let elapsed = Int(Date().timeIntervalSince(startTime ?? Date()))
        accumulatedSeconds += elapsed
        isTimerRunning = false
        startTime = nil
        timer?.invalidate()
        timer = nil

        SudokuStorage.shared.elapsedSeconds = accumulatedSeconds
        persistCurrentGame()
    }

    func resetTimer() {
        isTimerRunning = false
        startTime = nil
        accumulatedSeconds = 0
        SudokuStorage.shared.elapsedSeconds = 0
        timer?.invalidate()
        timer = nil
    }

    func toggleTimer() {
        isTimerRunning ? pauseTimer() : startTimer()
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

    private func countSolutions(_ board: inout [[Int]], limit: Int = 2) -> Int {
        var count = 0

        func backtrack(_ r: Int, _ c: Int) {
            if r == 9 {
                count += 1
                return
            }
            if count >= limit { return }

            let (nextR, nextC) = (c == 8 ? (r + 1, 0) : (r, c + 1))
            if board[r][c] != 0 {
                backtrack(nextR, nextC)
            } else {
                for num in 1...9 {
                    if isValid(board: board, row: r, col: c, num: num) {
                        board[r][c] = num
                        backtrack(nextR, nextC)
                        board[r][c] = 0
                    }
                }
            }
        }

        backtrack(0, 0)
        return count
    }

    private func generateSolvedBoard() -> [[Int]] {
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = solveSudoku(board: &board)
        
        // Digit shuffle
        let digitMap = (1...9).shuffled()
        for row in 0..<9 {
            for col in 0..<9 {
                let num = board[row][col]
                if num != 0 {
                    board[row][col] = digitMap[num - 1]
                }
            }
        }

        // Swap rows within bands (groups of 3 rows)
        for band in 0..<3 {
            let rows = (0..<3).map { band * 3 + $0 }.shuffled()
            for i in 0..<3 {
                board.swapAt(band * 3 + i, rows[i])
            }
        }

        // Transpose (flip rows and columns)
        if Bool.random() {
            board = (0..<9).map { row in (0..<9).map { col in board[col][row] } }
        }

        // Swap row bands (0-2, 3-5, 6-8)
        let bandOrder = [0, 1, 2].shuffled()
        var newBoard = board
        for (i, band) in bandOrder.enumerated() {
            for j in 0..<3 {
                newBoard[i * 3 + j] = board[band * 3 + j]
            }
        }
        board = newBoard

        // Swap column stacks (0-2, 3-5, 6-8)
        let stackOrder = [0, 1, 2].shuffled()
        board = board.map { row in
            var newRow = row
            for (i, stack) in stackOrder.enumerated() {
                for j in 0..<3 {
                    newRow[i * 3 + j] = row[stack * 3 + j]
                }
            }
            return newRow
        }

        shuffleSudoku(&board)
        return board
    }

    func generateNewPuzzle() {
        let difficulty = SudokuStorage.shared.difficulty
        print("선택된 난이도: \(difficulty)")

        var puzzle = generateSolvedBoard()
        let fullSolution = puzzle

        let removeCount: Int
        switch difficulty {
        case .debug:
            removeCount = 1
        case .easy:
            removeCount = 30
        case .normal:
            removeCount = 45
        case .hard:
            removeCount = 60
        case .expert:
            removeCount = 70
        }

        var removed = 0
        while removed < removeCount {
            let row = Int.random(in: 0..<9)
            let col = Int.random(in: 0..<9)
            if puzzle[row][col] != 0 {
                let original = puzzle[row][col]
                puzzle[row][col] = 0
                var testBoard = puzzle
                if countSolutions(&testBoard) == 1 {
                    removed += 1
                } else {
                    puzzle[row][col] = original
                }
            }
        }

        self.board = puzzle
        self.pencilMarks = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
        SudokuStorage.shared.pencilMarks = self.pencilMarks
        self.solution = fullSolution
        SudokuStorage.shared.solution = fullSolution
        self.fixedCells = Set()

        for row in 0..<9 {
            for col in 0..<9 {
                if puzzle[row][col] != 0 {
                    fixedCells.insert("\(row)-\(col)")
                }
            }
        }
        SudokuStorage.shared.fixedCells = fixedCells
        isSolutionDisplayed = false
    }

    func isBoardCorrect() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row][col] == 0 { return false }  // 아직 다 안 채워짐
                if board[row][col] != solution[row][col] { return false }
            }
        }
        return true
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
        SudokuStorage.shared.board = board
        // Always preserve pencil marks
    }
    
    func updatePencilMark(row: Int, col: Int, value: Int) {
        guard board[row][col] == 0 else { return }
        pencilMarks[row][col][value].toggle()
        SudokuStorage.shared.pencilMarks = pencilMarks
    }
    
    func markSuccess() {
        SudokuStorage.shared.recordSuccess()
    }

    func markGiveUp() {
        SudokuStorage.shared.recordGiveUp()
    }
    
    func showSolution() {
        isSolutionDisplayed = true
        pauseTimer()
        board = SudokuStorage.shared.solution
    }
    
//    func resumeAfterSolution() {
//        isSolutionDisplayed = false
//        startTimer()
//    }
    
    private func loadFromStorage() {
        let board = SudokuStorage.shared.board
        if board.flatMap({ $0 }).allSatisfy({ $0 == 0 }) {
            generateNewPuzzle()
            resetTimer()
            return
        }
        
        self.accumulatedSeconds = SudokuStorage.shared.elapsedSeconds
        self.board = SudokuStorage.shared.board
        self.solution = SudokuStorage.shared.solution
        self.fixedCells = SudokuStorage.shared.fixedCells
        self.pencilMarks = SudokuStorage.shared.pencilMarks
        self.selectedCell = nil
        self.isSolved = SudokuStorage.shared.isSolved 
    }
    
    func persistCurrentGame() {
        if isTimerRunning {
            accumulatedSeconds += Int(Date().timeIntervalSince(startTime ?? Date()))
            startTime = Date()
        }

        SudokuStorage.shared.elapsedSeconds = accumulatedSeconds
        SudokuStorage.shared.board = self.board
        SudokuStorage.shared.solution = self.solution
        SudokuStorage.shared.fixedCells = self.fixedCells
        SudokuStorage.shared.pencilMarks = self.pencilMarks
        SudokuStorage.shared.isSolved = self.isSolved 
    }
    
    private func shuffleSudoku(_ board: inout [[Int]]) {
        for _ in 0..<10 {
            // Swap rows within each band
            for band in 0..<3 {
                let row1 = band * 3 + Int.random(in: 0..<3)
                let row2 = band * 3 + Int.random(in: 0..<3)
                board.swapAt(row1, row2)
            }

            // Swap columns within each stack
            for stack in 0..<3 {
                let col1 = stack * 3 + Int.random(in: 0..<3)
                let col2 = stack * 3 + Int.random(in: 0..<3)
                for i in 0..<9 {
                    board[i].swapAt(col1, col2)
                }
            }

            // Transpose occasionally
            if Bool.random() {
                board = (0..<9).map { i in (0..<9).map { j in board[j][i] } }
            }
        }
    }
}
