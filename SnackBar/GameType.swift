//
//  GameType.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import Foundation

enum GameType: String, CaseIterable, Identifiable {
    case sudoku = "스도쿠"
    case spellingNabi = "스펠링 나비"
    case mineSweeper = "지뢰찾기"
    case game2048 = "2048"
    case slidingPuzzle = "슬라이딩 퍼즐"

    var id: String { rawValue }

    var displayName: String {
        return rawValue
    }
    
    var index: Int {
        switch self {
        case .sudoku: return 0
        case .spellingNabi: return 1
        case .mineSweeper: return 2
        case .game2048: return 3
        case .slidingPuzzle: return 4
        }
    }
}
