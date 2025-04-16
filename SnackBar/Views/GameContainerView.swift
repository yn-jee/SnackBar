//
//  GameContainerView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import SwiftUI

struct GameContainerView: View {
    @ObservedObject var controller = MainViewController.shared

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 40)
                        .foregroundColor(Color.white.opacity(0.37))
                    GameSelectorView()
                        .frame(width: controller.contentWidth, height: controller.selectorHeight)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .offset(y: -20)
            }
            .frame(width: controller.contentWidth, height: controller.selectorHeight)
            .background(Color.white.opacity(0.3))
            
            Divider()
            
            VStack(spacing: 0) {
                ZStack {
                    switch controller.currentGame {
                    case .sudoku:
                        SudokuView()
                            .transition(.opacity)
                    case .spellingNabi:
                        Text("스펠링 나비 뷰")
                            .transition(.opacity)
                    case .mineSweeper:
                        Text("지뢰찾기 뷰")
                            .transition(.opacity)
                    case .game2048:
                        Text("2048 뷰")
                            .transition(.opacity)
                    case .slidingPuzzle:
                        Text("슬라이딩 퍼즐 뷰")
                            .transition(.opacity)
                    }
                }
                .frame(minHeight: controller.contentHeight)
    
                Divider()

                VStack(spacing: 0) {
                    MenuRow(title: "설정", keyEquivalent: nil) {
                        
                    }
                    MenuRow(title: "종료", keyEquivalent: "q") {
                        NotificationCenter.default.post(name: .gameWindowDidClose, object: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            NSApp.terminate(nil)
                        }
                    }
                }
                .frame(height: controller.footerHeight * 2)
                .padding(5)
            }
        }
        .frame(width: controller.contentWidth, height: controller.totalHeight)
        .background(Color.white.opacity(0.1))
        .onChange(of: controller.currentGame) {
            if controller.currentGame != .sudoku {
                SudokuManager.shared.pauseTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameWindowDidClose)) { _ in
            if controller.currentGame == .sudoku {
                SudokuManager.shared.pauseTimer()
            }
        }
    }
}


struct MenuRow: View {  // NSPopover에서 NSMenu와 같은 스타일의 menu item을 생성하기 위함
    @ObservedObject var controller = MainViewController.shared
    let title: String
    let keyEquivalent: String?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(isHovered ? .white : .primary)

            if let key = keyEquivalent {
                Group {
                    Text("⌘ \(key.uppercased())")
                        .foregroundColor(isHovered ? .white : .primary)
                        .opacity(isHovered ? 1 : 0.5)
                }
            }
        }
        .frame(height: controller.footerHeight)
        .padding(.horizontal, 9)
        .background(
            ZStack {
                if isHovered {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.accentColor)
                }
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
