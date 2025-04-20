import SwiftUI

struct SudokuCellView: View, Equatable {
    @ObservedObject var manager = SudokuManager.shared
    @ObservedObject var controller = MainViewController.shared
    
    let row: Int
    let col: Int
    let value: Int
    let isSelected: Bool
    let isFixed: Bool
    let pencilMarks: [Bool]
    let isSolutionDisplayed: Bool
    let isSolved: Bool
    let isGenerating: Bool
    let isTimerRunning: Bool
    let wasRunningBeforeWindowHide: Bool
    let mainColor: Color
    let colorScheme: ColorScheme
    let onTap: () -> Void

    static func == (lhs: SudokuCellView, rhs: SudokuCellView) -> Bool {
        lhs.row == rhs.row &&
        lhs.col == rhs.col &&
        lhs.value == rhs.value &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isFixed == rhs.isFixed &&
        lhs.pencilMarks == rhs.pencilMarks &&
        lhs.isSolutionDisplayed == rhs.isSolutionDisplayed &&
        lhs.isSolved == rhs.isSolved &&
        lhs.isGenerating == rhs.isGenerating &&
        lhs.isTimerRunning == rhs.isTimerRunning &&
        lhs.wasRunningBeforeWindowHide == rhs.wasRunningBeforeWindowHide
    }
    
    private var isSameAsSelected: Bool {
        guard let selected = manager.selectedCell else { return false }
        let selectedValue = manager.board[selected.row][selected.col]
        return selectedValue != 0 &&
               selectedValue == value &&
               (selected.row != row || selected.col != col)
    }

    var body: some View {
        ZStack {
            if value != 0, let selectedValue = selectedCellValue, selectedValue == value && !isSelected {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(mainColor.opacity(0.7), lineWidth: 2)
                    .strokeBorder(mainColor.opacity(0.7), lineWidth: 3)
                    .padding(1)
            }

            if value == 0 {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { subRow in
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { subCol in
                                let pencilValue = subRow * 3 + subCol
                                if pencilMarks[pencilValue] {
                                    Text("\(pencilValue + 1)")
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundColor(.primary.opacity(0.6))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale))
                .animation(isTimerRunning ? .easeInOut(duration: 0.15) : nil, value: value)
            }

            if isSameAsSelected {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(mainColor.opacity(0.7), lineWidth: 2)
                    .strokeBorder(mainColor.opacity(0.7), lineWidth: 3)
                    .padding(1)
            }
            
            Text("\(value)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(
                    isFixed
                    ? (colorScheme == .light ? .black : .white)
                    : controller.adjustedAccentColor(brightnessAdjustment: colorScheme == .light ? -0.3 : 0.3)
                )
                .scaleEffect(value == 0 ? 0 : 1)
                .opacity((manager.isSolutionDisplayed || manager.isSolved) ? 1 :
                         (value == 0 || manager.isGeneratingPuzzle || !manager.isTimerRunning || !manager.wasRunningBeforeWindowHide) ? 0 : 1)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.15), value: value)
        }
        .frame(width: 30, height: 30)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? mainColor : Color.clear, lineWidth: 2)
                .padding(1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .scaleEffect(isSelected ? CGSize(width: 1.1, height: 1.1) : CGSize(width: 1.0, height: 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.2), value: isSelected)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .fill(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .opacity(
                    (isSolutionDisplayed || isSolved)
                    ? 0.0
                    : (isGenerating || !isTimerRunning || !wasRunningBeforeWindowHide) ? 1.0 : 0.0
                )
                .animation(
                    .easeInOut(duration: 0.15),
                    value: isGenerating || !isTimerRunning || !wasRunningBeforeWindowHide || isSolutionDisplayed || isSolved
                )
        )
    }

    private var selectedCellValue: Int? {
        if isSelected {
            return value
        }
        return nil
    }
}
