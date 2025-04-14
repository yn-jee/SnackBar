//
//  SudokuView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import SwiftUI

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
    
    @ViewBuilder
    private func backgroundCell(row: Int, col: Int, isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(((row / 3 + col / 3) % 2 == 0 ? Color.white.opacity(0.3) : Color.gray.opacity(0.2)))
            .frame(width: 30, height: 30)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 1)
            )
            .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
    }
    
    @ViewBuilder
    private func foregroundCell(row: Int, col: Int, value: Int, isSelected: Bool, isFixed: Bool) -> some View {
        ZStack {
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
    }

    private var sudokuGrid: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 2) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \.self) { col in
                            let isSelected: Bool = manager.selectedCell?.row == row && manager.selectedCell?.col == col
                            backgroundCell(row: row, col: col, isSelected: isSelected)
                        }
                    }
                }
            }
            .zIndex(0)

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

            VStack(spacing: 2) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \.self) { col in
                            let value: Int = manager.board[row][col]
                            let isSelected: Bool = manager.selectedCell?.row == row && manager.selectedCell?.col == col
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
            sudokuGrid

            Divider().padding([.top, .bottom], 8)

            HStack(spacing: 3) {
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
                                    manager.pencilMarks[selected.row][selected.col][num - 1].toggle()
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

        }
        .padding()
        .onAppear {
            DispatchQueue.main.async {
                controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)
            }
        }
        .onChange(of: colorScheme) {
            DispatchQueue.main.async {
                controller.mainColor = controller.adjustedAccentColor(brightnessAdjustment: 0)
            }
        }

    }
}
