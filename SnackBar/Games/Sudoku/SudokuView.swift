//
//  SudokuView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import SwiftUI
import AppKit

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
//    @StateObject private var gameTimer = GameTimer()
    
    @ViewBuilder
    private func backgroundCell(row: Int, col: Int, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(((row / 3 + col / 3) % 2 == 0 ? Color.white.opacity(0.3) : Color.gray.opacity(0.2)))
            .frame(width: 30, height: 30)
            .overlay(
                (manager.isTimerRunning && !manager.isSolutionDisplayed) ?
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
    
    @ViewBuilder
    private func foregroundCell(row: Int, col: Int, value: Int, isSelected: Bool, isFixed: Bool) -> some View {
        ZStack {
            // Check if the value matches the selected cell's value
            let isSameAsSelected = {
                if let selected = manager.selectedCell {
                    return manager.board[selected.row][selected.col] != 0 &&
                           manager.board[selected.row][selected.col] == value &&
                           (selected.row != row || selected.col != col)
                }
                return false
            }()
            
            // Add overlay if value matches and is not zero
            if value != 0 && isSameAsSelected {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(controller.mainColor.opacity(0.7), lineWidth: 2)
                    .strokeBorder(controller.mainColor.opacity(0.7), lineWidth: 3)
                    .padding(1)
            }

            // Pencil marks view (value == 0)
            if value == 0 {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { subRow in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { subCol in
                                let pencilValue = subRow * 3 + subCol
                                if manager.pencilMarks[row][col][pencilValue] {
                                    Text("\(pencilValue + 1)")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.primary.opacity(0.6))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.15), value: value)
            }

            // Main number view (value != 0)
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(
                    isFixed
                    ? (colorScheme == .light ? Color.black : Color.white)
                    : (colorScheme == .light
                       ? controller.adjustedAccentColor(brightnessAdjustment: -0.3)
                       : controller.adjustedAccentColor(brightnessAdjustment: 0.3))
                )
                .scaleEffect(value == 0 ? 0 : 1)
                .opacity(value == 0 ? 0 : 1)
                .animation(.easeInOut(duration: 0.15), value: value)
        }
        .id("cell-\(row)-\(col)")
        .frame(width: 30, height: 30)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? controller.mainColor : Color.clear, lineWidth: 2)
                .padding(1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manager.selectedCell = (row, col)
        }
        .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
        .overlay(
            (manager.isSolutionDisplayed == false && !manager.isTimerRunning) ?
            RoundedRectangle(cornerRadius: 5)
                .fill(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            : nil
        )
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
                            let isFixed: Bool = manager.fixedCells.contains("\(row)-\(col)")

                            foregroundCell(row: row, col: col, value: value, isSelected: isSelected, isFixed: isFixed)
                        }
                    }
                }
            }
            .zIndex(2)
        }
    }

    var body: some View {
        VStack {
            Text(manager.formattedElapsedTime)
                .font(.system(size: 12, weight: .regular))
                .frame(maxWidth: .infinity)
                .opacity(0.7)
            
            ZStack {
                VStack {
                    ZStack {
                        sudokuGrid
                        //                            .overlay(
                        //                                !gameTimer.isRunning ?
                        //                                RoundedRectangle(cornerRadius: 5)
                        //                                    .fill(.ultraThinMaterial)
                        //                                    .opacity(0.8)
                        //                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                        //                                : nil
                        //                            )
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
                        .disabled((!manager.isTimerRunning && manager.isSolutionDisplayed))
                        Button("난이도") { }
                        Button("새 게임") {
                            manager.generateNewPuzzle()
                            manager.resetTimer()
                            manager.startTimer()
                        }
                        Button("정답") {
                            manager.showSolution()
                        }
                        Button("스탯") { }
                    }
                    .font(.system(size: 11, weight: .regular))
                    .buttonStyle(SubtleButtonStyle())
                }
            }
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
            DispatchQueue.main.async {
                controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)
                manager.startTimer()
            }
        }
        .onChange(of: colorScheme) {
            DispatchQueue.main.async {
                controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)
            }
        }
        .onChange(of: controller.currentGame) {
            if controller.currentGame == .sudoku {
                manager.startTimer()
            } else {
                manager.pauseTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWindowDidClose)) { _ in
            DispatchQueue.main.async {
                manager.pauseTimer()
                manager.persistCurrentGame()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWindowDidHide)) { _ in
            DispatchQueue.main.async {
                manager.pauseTimer()
                manager.persistCurrentGame()
            }
        }
        .onDisappear() {
            DispatchQueue.main.async {
                manager.pauseTimer()
                manager.persistCurrentGame()
            }
        }
    }
}
