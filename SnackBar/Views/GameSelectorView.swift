//
//  GameSelectorView.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import SwiftUI

struct GameSelectorView: View {
    @ObservedObject var controller = MainViewController.shared
    @Namespace private var animationNamespace
    @State private var selectedGame: GameType = MainViewController.shared.currentGame
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                ForEach(GameType.allCases, id: \.self) { game in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGame = game
                            controller.selectGame(game) 
                        }
                    }) {
                        Text(game.displayName)
                            .foregroundColor(selectedGame == game ? .white : .primary)
                            .padding(.vertical, 3)
                            .padding(.horizontal, selectedGame == game ? 8 : 12)
                            .font(.system(size: 12))
                            .background(
                                ZStack {
                                    if selectedGame == game {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.accentColor)
                                            .matchedGeometryEffect(id: "segmentBackground", in: animationNamespace)
                                    }
                                }
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
            .padding(.horizontal)
        }
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
