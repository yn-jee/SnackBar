//
//  SnackBarApp.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import SwiftUI

@main
struct SnackBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()  // 메뉴바 Agent 앱
        }
    }
}
