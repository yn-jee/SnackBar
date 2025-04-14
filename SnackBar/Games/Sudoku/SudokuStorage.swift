//
//  SudokuStorage.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//

import Foundation

enum SudokuDifficulty: String, CaseIterable {
    case easy, normal, hard
}

class SudokuStorage {
    static let shared = SudokuStorage()

    private let successKey = "sudokuSuccessCount"
    private let giveUpKey = "sudokuGiveUpCount"
    
    var successCount: Int {
        get { UserDefaults.standard.integer(forKey: successKey) }
        set { UserDefaults.standard.set(newValue, forKey: successKey) }
    }

    var giveUpCount: Int {
        get { UserDefaults.standard.integer(forKey: giveUpKey) }
        set { UserDefaults.standard.set(newValue, forKey: giveUpKey) }
    }

    func recordSuccess() {
        successCount += 1
    }

    func recordGiveUp() {
        giveUpCount += 1
    }
    
    private let difficultyKey = "sudokuDifficulty"

    var difficulty: SudokuDifficulty {
        get {
            let raw = UserDefaults.standard.string(forKey: difficultyKey) ?? "normal"
            return SudokuDifficulty(rawValue: raw) ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: difficultyKey)
        }
    }
}

// 현재 풀고 있는 문제랑 진행상황도 저장
// 선택한 칸 안에 숫자가 적혀 있다면 그 숫자랑 같은 칸의 숫자들은 mainColor에 오패시티 약간 준 테두리로 표시되게 해줘
