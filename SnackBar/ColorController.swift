//
//  ColorController.swift
//  SnackBar
//
//  Created by 나윤지 on 4/14/25.
//
//
//import Foundation
//import AppKit
//import SwiftUICore
//
//final class ColorController: ObservableObject {
//    static let shared = ColorController()
//    
//    static func adjustedAccentColor(brightnessAdjustment: Double) -> Color {
//        let baseColor = UIColor(Color.accentColor)
//        var red: CGFloat = 0
//        var green: CGFloat = 0
//        var blue: CGFloat = 0
//        var alpha: CGFloat = 0
//        
//        baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//        
//        // 밝기 조절
//        let adjustedRed = max(min(red + CGFloat(brightnessAdjustment), 1.0), 0.0)
//        let adjustedGreen = max(min(green + CGFloat(brightnessAdjustment), 1.0), 0.0)
//        let adjustedBlue = max(min(blue + CGFloat(brightnessAdjustment), 1.0), 0.0)
//        
//        return Color(UIColor(red: adjustedRed, green: adjustedGreen, blue: adjustedBlue, alpha: alpha))
//    }
//    
//}
