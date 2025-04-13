//
//  SudokuView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SudokuView: View {
    @ObservedObject var manager = SudokuManager.shared

    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 2) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<9, id: \.self) { col in
                                let value = manager.board[row][col]
                                let isSelected = manager.selectedCell?.row == row && manager.selectedCell?.col == col
                                let isFixed = manager.fixedCells.contains("\(row)-\(col)")
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill((isFixed ? Color.gray.opacity(0.3) : Color.white.opacity(0.3)))
                                }
                                .frame(width: 30, height: 30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isSelected ? Color.clear : Color.gray, lineWidth : 1)
                                )
                                .contentShape(Rectangle())
                                .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
                            }
                        }
                    }
                }
                .zIndex(0)
                
                VStack(spacing: 2) {
                    ForEach(0..<9, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<9, id: \.self) { col in
                                let value = manager.board[row][col]
                                let isSelected = manager.selectedCell?.row == row && manager.selectedCell?.col == col
                                let isFixed = manager.fixedCells.contains("\(row)-\(col)")
                                
                                ZStack {
                                    Text(value == 0 ? "" : "\(value)")
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 30, height: 30)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    manager.selectedCell = (row, col)
                                }
                                .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
                                .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
                            }
                        }
                    }
                }
                .zIndex(1)
            }

            Divider().padding(.top, 10)

            HStack(spacing: 8) {
                ForEach(1...9, id: \.self) { num in
                    Button("\(num)") {
                        if let selected = manager.selectedCell {
                            manager.updateCell(row: selected.row, col: selected.col, value: num)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.5))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)

            Button("지우기") {
                if let selected = manager.selectedCell {
                    manager.updateCell(row: selected.row, col: selected.col, value: 0)
                }
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.top, 8)
        }
        .padding()
    
    }
}
