//
//  SudokuView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import SwiftUI
import AppKit
import ConfettiSwiftUI

struct KeyEventHandlingView: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyCaptureView: NSView {
    var onKeyDown: ((NSEvent) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onKeyDown?(event)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }
}

struct SubtleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .light ? Color.white.opacity((configuration.isPressed ? 0.6 : 0.4)) : Color.black.opacity(configuration.isPressed ? 0.3 : 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                )
            .foregroundColor(.primary)

    }
}

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .light ? Color.white.opacity(0.7) : Color.black.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

struct SudokuView: View {
    @ObservedObject var manager = SudokuManager.shared
    @ObservedObject var controller = MainViewController.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var showConfetti: Bool = false
    @State private var solvedCount = UserDefaults.standard.integer(forKey: "sudokuSolvedCount")
    @State private var giveUpCount: Int = UserDefaults.standard.integer(forKey: "sudokuGiveUpCount")
    @State private var confettiCount: Int = 0
    @State private var showSaveMessage: Bool = false
    @State private var selectedDifficulty: SudokuDifficulty = SudokuStorage.shared.difficulty
    @State private var currentDifficulty: SudokuDifficulty = SudokuStorage.shared.difficulty
    
    @State private var isStatsPresented: Bool = false
    
    @State private var hasFullyAppearedOnce = false
    @State private var isReopenedFromClose = false
    
//    @StateObject private var gameTimer = GameTimer()
    
    @ViewBuilder
    private func backgroundCell(row: Int, col: Int, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(((row / 3 + col / 3) % 2 == 0 ? Color.white.opacity(0.3) : Color.gray.opacity(0.2)))
            .frame(width: 30, height: 30)
            .overlay(
                !(manager.isGeneratingPuzzle || (!manager.isTimerRunning && !manager.isSolved && !manager.isSolutionDisplayed)) ?
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 1)
                : nil
            )
            .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
//            .overlay(
//                !gameTimer.isRunning ?
//                RoundedRectangle(cornerRadius: 5)
//                    .fill(.ultraThinMaterial)
//                    .clipShape(RoundedRectangle(cornerRadius: 5))
//                : nil
//            )
    }
    

    private var sudokuGrid: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 2) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \.self) { col in
                        let isSelected: Bool = {
                            if let selected = manager.selectedCell {
                                return selected.row == row && selected.col == col
                            }
                            return false
                        }()
                            backgroundCell(row: row, col: col, isSelected: isSelected)
                        }
                    }
                }
            }
            .zIndex(0)

            if (manager.isSolutionDisplayed == false && manager.isTimerRunning) {
                if let selected = manager.selectedCell {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(controller.mainColor, lineWidth: 1.5)
                        .frame(width: 286, height: 30)
                        .opacity(1)
                        .offset(x: 0, y: CGFloat(selected.row) * 32)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.15), value: selected.row)
                        .zIndex(1)
                    
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(controller.mainColor, lineWidth: 1.5)
                        .frame(width: 30, height: 286)
                        .opacity(1)
                        .offset(x: CGFloat(selected.col) * 32, y: 0)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.15), value: selected.col)
                        .zIndex(1)
                }
            }

            VStack(spacing: 2) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \.self) { col in
                            let value: Int = manager.board[row][col]
                            let isSelected: Bool = {
                                if let selected = manager.selectedCell {
                                    return selected.row == row && selected.col == col
                                }
                                return false
                            }()
                            let isFixed: Bool = manager.isRestored && manager.fixedCells.contains("\(row)-\(col)")
                            let selectedValue = manager.selectedCell.map { manager.board[$0.row][$0.col] }

                            let isSameAsSelected = selectedValue != nil &&
                                                   selectedValue != 0 &&
                                                   selectedValue == manager.board[row][col] &&
                                                   (manager.selectedCell?.row != row || manager.selectedCell?.col != col)
                            
                            SudokuCellView(
                                row: row,
                                col: col,
                                value: manager.board[row][col],
                                isSelected: isSelected,
                                isFixed: isFixed,
                                pencilMarks: manager.pencilMarks[row][col],
                                isSolutionDisplayed: manager.isSolutionDisplayed,
                                isSolved: manager.isSolved,
                                isGenerating: manager.isGeneratingPuzzle,
                                isTimerRunning: manager.isTimerRunning,
                                wasRunningBeforeWindowHide: manager.wasRunningBeforeWindowHide,
                                mainColor: controller.mainColor,
                                colorScheme: colorScheme,
                                onTap: {
                                    manager.selectedCell = (row, col)
                                }
                            )
                        }
                    }
                }
            }
            .zIndex(2)
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(manager.formattedElapsedTime)
                    .font(.system(size: 12, weight: .regular))
                    .frame(maxWidth: .infinity)
                    .opacity(0.7)
                Text("\(label(for: currentDifficulty))")
                    .font(.system(size: 12, weight: .regular))
                    .frame(maxWidth: .infinity)
                    .opacity(0.7)
            }
            .frame(width: 150)
            
            ZStack {
                VStack {
                    ZStack {
                        sudokuGrid
                            .overlay(
                                manager.isGeneratingPuzzle ?
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.5)
                                    .transition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: manager.isGeneratingPuzzle)
                                : nil
                            )
                            .zIndex(0)
                        
                        if manager.isGeneratingPuzzle {
                            VStack {
                                ProgressView("퍼즐 생성 중...")
                                    .scaleEffect(0.8)
                            }
                            .frame(width: 286, height: 286)
                            .zIndex(11)
                        }
                        
                        if showConfetti {
                            VStack {
                                Spacer()
                                Text("Congratulations!")
                                    .font(.system(size: 16, weight: .heavy))
                                Text("지금까지 푼 스도쿠: \(solvedCount)")
                                    .font(.system(size: 11))
                                    .padding(.top, 4)
                                Spacer()
                            }
                            .frame(width: 200, height: 200)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .blur(radius: 20)
                                    .opacity(0.8)
                                    .ignoresSafeArea()
                            )
                            .zIndex(11)
                            .transition(.opacity)
                            .animation(.easeOut(duration: 1.0), value: showConfetti)
                        }
                    }
                    .frame(width: 288, height: 288)
                    
                    Divider().padding(6)
                    
                    HStack(spacing: 3) {    // 입력 버튼
                        Button(action: {
                            manager.isPencilMode.toggle()
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 24)
                                .foregroundColor(manager.isPencilMode ? controller.mainColor : .primary)
                                .scaleEffect(manager.isPencilMode ? 1.15 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: manager.isPencilMode)
                            
                        }
                        .buttonStyle(PressableButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(manager.isPencilMode ? controller.mainColor : Color.clear, lineWidth: 2)
                                .padding(1)
                        )
                        .scaleEffect(manager.isPencilMode ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: manager.isPencilMode)
                        
                        Spacer()
                            .frame(width: 8)
                        
                        ForEach(1...9, id: \.self) { num in
                            Button(action: {
                                if let selected = manager.selectedCell {
                                    if manager.isPencilMode {
                                        if manager.board[selected.row][selected.col] == 0 {
                                            manager.updatePencilMark(row: selected.row, col: selected.col, value: num - 1)
                                        }
                                    } else {
                                        manager.updateCell(row: selected.row, col: selected.col, value: num)
                                        
                                        if manager.isBoardCorrect() {
                                            manager.pauseTimer()
                                            manager.isSolved = true
                                            showConfetti = true
                                            solvedCount += 1
                                            confettiCount += 1
                                            manager.markSuccess()
                                            UserDefaults.standard.set(solvedCount, forKey: "sudokuSolvedCount")

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                            withAnimation(.easeOut(duration: 1.0)) {
                                                showConfetti = false
                                            }
                                        }
                                        }
                                    }
                                }
                            }) {
                                Text("\(num)")
                                    .frame(width: 24, height: 24)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .frame(width: 24, height: 24)
                            .scaleEffect(1.0)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        }
                        
                        Spacer()
                            .frame(width: 8)
                        
                        Button(action: {
                            if let selected = manager.selectedCell {
                                manager.updateCell(row: selected.row, col: selected.col, value: 0)
                            }
                        }) {
                            Image(systemName: "eraser")
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 36, height: 24)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.horizontal)
                    .disabled(!(manager.isTimerRunning && !manager.isSolutionDisplayed))
                    
                    HStack(spacing: 12) {
                        Button("정지/재개") {
                            manager.toggleTimer()
                        }
                        .disabled(
                            manager.isSolutionDisplayed
                            || manager.isSolved
                            || manager.isGeneratingPuzzle
                        )
                        Button("새 게임") {
                            SudokuStorage.shared.difficulty = selectedDifficulty
                            showConfetti = false
                            manager.isSolved = false
                            manager.resetTimer()
                            manager.isGeneratingPuzzle = true

                            Task.detached(priority: .userInitiated) {
                                manager.generateNewPuzzle {
                                    // 퍼즐 생성 완료 후 실행되는 블록
                                    Task { @MainActor in
                                        manager.isGeneratingPuzzle = false
                                        currentDifficulty = SudokuStorage.shared.difficulty
                                        
                                        if NSApp.isActive {
                                            manager.startTimer()
                                            manager.wasRunningBeforeWindowHide = true  // 창이 떠 있는 동안 타이머 시작
                                        } else {
                                            manager.wasRunningBeforeWindowHide = true  // 창이 뜰 때까지 기억하기
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button("포기") {
                            manager.showSolution()
                            manager.markGiveUp()
                        }
                        .disabled(
                            manager.isSolutionDisplayed
                            || manager.isSolved
                            || manager.isGeneratingPuzzle
                        )
                        Menu("난이도") {
                            ForEach(SudokuDifficulty.allCases, id: \.self) { difficulty in
//                                if difficulty != .debug {
                                    Button {
                                        selectedDifficulty = difficulty
                                        handleSettingChange()
                                    } label: {
                                        Label(
                                            title: {
                                                Text(label(for: difficulty))
                                                    .font(.system(size: 12))
                                            },
                                            icon: {
                                                if selectedDifficulty == difficulty {
                                                    Image(systemName: "checkmark")
                                                        .imageScale(.small)
                                                        .frame(width: 7, height: 7)
                                                }
                                            }
                                        )
                                    }
                                    .labelStyle(.titleAndIcon)
//                                }
                            }
                        }
                        Button("스탯") {
                            isStatsPresented.toggle()
                        }
                        .popover(isPresented: $isStatsPresented, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("총 푼 스도쿠: \(solvedCount) 개")

                                ForEach(SudokuDifficulty.allCases, id: \.self) { diff in
                                    Text("\(label(for: diff)): \(SudokuStorage.shared.successCount(for: diff)) 개")
                                }

                                Text("포기한 게임: \(SudokuStorage.shared.giveUpCount) 개")
                            }
                            .padding()
                            .frame(width: 150)
                        }
                    }
                    .font(.system(size: 12, weight: .regular))
                    .buttonStyle(SubtleButtonStyle())
                }
            }
            .confettiCannon(trigger: $confettiCount)
            
            KeyEventHandlingView { event in
                if let selected = manager.selectedCell,
                   let chars = event.charactersIgnoringModifiers,
                   let number = Int(chars), (1...9).contains(number) {
                    if manager.isPencilMode {
                        if manager.board[selected.row][selected.col] == 0 {
                            manager.updatePencilMark(row: selected.row, col: selected.col, value: number - 1)
                        }
                    } else {
                        let current = manager.board[selected.row][selected.col]
                        if current == number {
                            manager.updateCell(row: selected.row, col: selected.col, value: 0)
                        } else {
                            manager.updateCell(row: selected.row, col: selected.col, value: number)
                            
                            if manager.isBoardCorrect() {
                                manager.pauseTimer()
                                manager.isSolved = true
                                showConfetti = true
                                solvedCount += 1
                                confettiCount += 1
                                manager.markSuccess()
                                UserDefaults.standard.set(solvedCount, forKey: "sudokuSolvedCount")

                                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                    withAnimation(.easeOut(duration: 1.0)) {
                                        showConfetti = false
                                    }
                                }
                            }
                        }
                    }
                } else if event.keyCode == 51 { // delete
                    if let selected = manager.selectedCell {
                        manager.updateCell(row: selected.row, col: selected.col, value: 0)
                    }
                }
                
            }
            .frame(width: 0, height: 0)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            NSApp.mainWindow?.makeFirstResponder(nil)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                initializeView()
            }
        }
        .onChange(of: colorScheme) {
            DispatchQueue.main.async {
                controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)
            }
        }
        .onChange(of: controller.currentGame) {
            if controller.currentGame == .sudoku {
                if manager.isSolved {
                    manager.pauseTimer()
                } else {
                    manager.startTimer()
                    manager.wasRunningBeforeWindowHide = true  // 명시적으로 시작한 경우로 기록
                }
            } else {
                DispatchQueue.main.async {
                    if manager.isTimerRunning {
                        manager.wasRunningBeforeWindowHide = true
                    }
                    manager.pauseTimer()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWindowDidClose)) { _ in
            DispatchQueue.main.async {
                if manager.isTimerRunning {
                    manager.wasRunningBeforeWindowHide = true
                }
                manager.pauseTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWindowDidHide)) { _ in
            DispatchQueue.main.async {
                if manager.isTimerRunning {
                    manager.wasRunningBeforeWindowHide = true
                }
                manager.pauseTimer()
            }
        }
        .onDisappear() {
            DispatchQueue.main.async {
                if manager.isTimerRunning {
                    manager.wasRunningBeforeWindowHide = true
                }
                manager.pauseTimer()
            }
        }
    }
    
    private func handleSettingChange() {
        withAnimation {
            showSaveMessage = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showSaveMessage = false
            }
        }
    }
    
    private func initializeView() {
        controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)

        if !UserDefaults.standard.bool(forKey: "sudokuDidAlreadyStart") {
            manager.wasRunningBeforeWindowHide = UserDefaults.standard.bool(forKey: "sudokuWasRunning")
            UserDefaults.standard.set(true, forKey: "sudokuDidAlreadyStart")
        }

        // 포기한 상태면 무조건 멈추고 종료
        if manager.isSolutionDisplayed || manager.isSolved {
            manager.pauseTimer()
            return
        }

        if manager.isGeneratingPuzzle || manager.isSolved {
            manager.pauseTimer()
        } else if manager.wasRunningBeforeWindowHide {
            manager.startTimer()
        } else {
            manager.pauseTimer()
        }
    }
    
    private func label(for difficulty: SudokuDifficulty) -> String {
        switch difficulty {
        case .debug: return "디버그"
        case .easy: return "쉬움"
        case .normal: return "보통"
        case .hard: return "어려움"
        case .expert: return "전문가"
        }
    }
}
