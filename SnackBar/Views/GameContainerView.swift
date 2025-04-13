//
//  GameContainerView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import SwiftUI

struct GameContainerView: View {
    @ObservedObject var controller = MainGameController.shared

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                GameSelectorView()
                    .frame(height: self.controller.selectorHeight)
                Divider()
            }
            .frame(height: self.controller.selectorHeight)

            ZStack {
                switch controller.currentGame {
                case .sudoku:
                    SudokuView()
                        .transition(.scale)
                case .spellingNabi:
                    Text("스펠링 나비 뷰")
                        .transition(.scale)
                case .mineSweeper:
                    Text("지뢰찾기 뷰")
                        .transition(.scale)
                case .game2048:
                    Text("2048 뷰")
                        .transition(.scale)
                case .slidingPuzzle:
                    Text("슬라이딩 퍼즐 뷰")
                        .transition(.scale)
                }
            }
            .frame(minWidth: 300, minHeight: self.controller.contentMinHeight)
            
            Divider()

            VStack(spacing: 0) {
                MenuRow(title: "설정", keyEquivalent: nil) {
                    NSApp.terminate(nil)
                }
                MenuRow(title: "종료", keyEquivalent: "q") {
                    NSApp.terminate(nil)
                }
            }
            .frame(height: self.controller.footerHeight * 2)
            .padding(5)
        }
        .frame(height: self.controller.totalHeight)
    }
}

struct MenuRow: View {  // NSPopover에서 NSMenu와 같은 스타일의 menu item을 생성하기 위함
    @ObservedObject var controller = MainGameController.shared
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
