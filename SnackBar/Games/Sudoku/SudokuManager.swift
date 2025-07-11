//
//  SudokuManager.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

final class SudokuManager: ObservableObject {
    static let shared = SudokuManager()
    @Published var isGeneratingPuzzle: Bool = false
    
    @Published var isSolved: Bool = SudokuStorage.shared.isSolved {
        didSet {
            SudokuStorage.shared.isSolved = isSolved
        }
    }

    @Published var accumulatedSeconds: Int = SudokuStorage.shared.elapsedSeconds {
        didSet {
            SudokuStorage.shared.elapsedSeconds = accumulatedSeconds
        }
    }
    @Published var board: [[Int]] = SudokuStorage.shared.board
    @Published var solution: [[Int]] = SudokuStorage.shared.solution
    @Published var fixedCells: Set<String> = SudokuStorage.shared.fixedCells
    @Published var isPencilMode: Bool = false
    @Published var pencilMarks: [[[Bool]]] = SudokuStorage.shared.pencilMarks
    @Published var isTimerRunning: Bool = false
    @Published var isSolutionDisplayed: Bool = false
    @Published var selectedCell: (row: Int, col: Int)? = nil
    
    @Published var isRestored: Bool = false     // 로딩 완료 플래그
    @Published var wasRunningBeforeWindowHide: Bool = false
    
    private var currentGenerationTask: DispatchWorkItem?    // 퍼즐 생성 중인지
    
    private var startTime: Date?
    private var timer: Timer?
    
    private init() {
        loadFromStorage()
        self.isRestored = true
        wasRunningBeforeWindowHide = UserDefaults.standard.bool(forKey: "sudokuWasRunning")
    }
    
    private var elapsedSecondsSnapshot: Int {
        accumulatedSeconds + (isTimerRunning && startTime != nil ? Int(Date().timeIntervalSince(startTime!)) : 0)
    }
    
    var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @Published var elapsedSeconds: Int = 0

    func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        startTime = Date()
        
        // 타이머 시작 딜레이 없도록 즉시 1회 반영
        DispatchQueue.main.async {
            self.elapsedSeconds = self.accumulatedSeconds
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.elapsedSeconds = self.accumulatedSeconds + Int(Date().timeIntervalSince(self.startTime ?? Date()))
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
        if isTimerRunning {
            wasRunningBeforeWindowHide = false
            pauseTimer()
        } else {
            wasRunningBeforeWindowHide = true
            startTimer()
        }
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
                    if count >= limit { return }
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

    func generateNewPuzzle(completion: @escaping @Sendable () -> Void) {
        currentGenerationTask?.cancel()
        
        let task = DispatchWorkItem {
            let difficultySnapshot = SudokuStorage.shared.difficulty
            print("선택된 난이도: \(difficultySnapshot)")

            var puzzle = self.generateSolvedBoard()
            let fullSolution = puzzle

            // 난이도별 제거 개수
            let removeCount: Int
            print("선택된 난이도: \(difficultySnapshot)")
            switch difficultySnapshot {
                case .debug:  removeCount = 1
                case .easy:   removeCount = 30
                case .normal: removeCount = 45
                case .hard:   removeCount = 53
                case .expert: removeCount = 64
            }
            
            SudokuStorage.shared.recordSuccess(for: difficultySnapshot)

            let baseOrder = Self.generateCellDigOrder()
            var candidateOrder = baseOrder
            var removed = 0
            var tried = Set<String>()

            for attempt in 0..<3 {
                for (row, col) in candidateOrder {
                    guard removed < removeCount else { break }
                    guard puzzle[row][col] != 0 else { continue }

                    let key = "\(row)-\(col)"
                    if tried.contains(key) { continue }

                    let backup = puzzle[row][col]
                    puzzle[row][col] = 0

                    var testBoard = puzzle
                    if self.countSolutions(&testBoard, limit: 2) == 1 {
                        removed += 1
                    } else {
                        puzzle[row][col] = backup
                        tried.insert(key)
                    }
                }

                // 목표 도달 시 break
                if removed >= removeCount { break }

                // 다음 시도용 셀 셔플
                candidateOrder = baseOrder.shuffled()
            }

            DispatchQueue.main.async {
                self.board = puzzle
                self.pencilMarks = Array(repeating: Array(repeating: Array(repeating: false, count: 9), count: 9), count: 9)
                SudokuStorage.shared.pencilMarks = self.pencilMarks
                self.solution = fullSolution
                SudokuStorage.shared.solution = fullSolution

                let newFixed = (0..<9).flatMap { row in
                    (0..<9).compactMap { col in
                        puzzle[row][col] != 0 ? "\(row)-\(col)" : nil
                    }
                }
                self.fixedCells = Set(newFixed)
                SudokuStorage.shared.fixedCells = self.fixedCells

                self.isSolutionDisplayed = false
                self.isGeneratingPuzzle = false

                print("✅ 저장 완료. fixedCells count = \(self.fixedCells.count)")
                print("✅ 저장 완료. fixedCells = \(self.fixedCells.sorted())")

                completion()
            }
        }
        
        currentGenerationTask = task
        DispatchQueue.global(qos: .userInitiated).async(execute: task)
    }
    
    private static func generateCellDigOrder() -> [(Int, Int)] {
        var order: [(Int, Int)] = []

        for row in 0..<9 {
            if row % 2 == 0 {
                for col in 0..<9 {
                    order.append((row, col))
                }
            } else {
                for col in (0..<9).reversed() {
                    order.append((row, col))
                }
            }
        }

        return order.shuffled() // 랜덤화 가능
    }

    func estimateDifficulty(for board: [[Int]]) -> Int {
        var score = 0

        for row in 0..<9 {
            for col in 0..<9 {
                if board[row][col] == 0 {
                    var possible = Set(1...9)

                    // 행
                    for i in 0..<9 { possible.remove(board[row][i]) }
                    // 열
                    for i in 0..<9 { possible.remove(board[i][col]) }
                    // 박스
                    let startRow = row / 3 * 3
                    let startCol = col / 3 * 3
                    for i in 0..<3 {
                        for j in 0..<3 {
                            possible.remove(board[startRow + i][startCol + j])
                        }
                    }

                    // 점수 부여 기준
                    switch possible.count {
                    case 1:
                        score += 1 // Naked Single
                    case 2:
                        score += 2 // Hidden Single 가능성 있음
                    case 3...4:
                        score += 3 // Naked Pair 또는 Hidden Pair 가능성
                    case 5...6:
                        score += 5 // X-Wing 또는 Medium급 기법 필요
                    default:
                        score += 7 // Hard급 기법 필요
                    }
                }
            }
        }

        return score
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
        let difficulty = SudokuStorage.shared.difficulty
        SudokuStorage.shared.recordSuccess(for: difficulty)
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
            self.isGeneratingPuzzle = true
            self.resetTimer()

            self.generateNewPuzzle {
                self.startTimer()
                self.isRestored = true  // 퍼즐 생성 후 복원 완료
            }
            return
        }

        self.accumulatedSeconds = SudokuStorage.shared.elapsedSeconds
        self.board = SudokuStorage.shared.board
        self.solution = SudokuStorage.shared.solution
        self.fixedCells = SudokuStorage.shared.fixedCells
        self.pencilMarks = SudokuStorage.shared.pencilMarks
        self.selectedCell = nil
        self.isSolved = SudokuStorage.shared.isSolved

        DispatchQueue.main.async {
            self.isRestored = true  // 복원 완료 시점 뷰에게 알림
        }
        print("✅ 복원 완료. fixedCells = \(fixedCells.sorted())")
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
