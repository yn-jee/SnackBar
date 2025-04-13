//
//  AppDelegate.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var instance: AppDelegate!
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil)
            button.imagePosition = .imageLeading
            button.target = self
        }
        
        ApplicationMenu.shared.attachToStatusBar(statusItem)
    }
}
