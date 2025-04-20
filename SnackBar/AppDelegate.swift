//
//  AppDelegate.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static private(set) var instance: AppDelegate!
    var popover: NSPopover!
    var window: NSWindow?
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: nil)
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(popoverDidClose), name: NSPopover.didCloseNotification, object: nil)
        ApplicationMenu.shared.attachToStatusBar(statusItem)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
                NotificationCenter.default.post(name: .gameWindowDidClose, object: nil)
            } else {
                if let button = statusItem.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }

    @objc func popoverDidClose(notification: Notification) {
        // SwiftUI 팝오버 또는 메인 팝오버가 열려 있으면 무시
        let isAnyPopoverVisible =
            (popover?.isShown ?? false) ||
            NSApp.windows.contains {
                String(describing: type(of: $0)).contains("NSPopoverWindow") && $0.isVisible
            }

        if isAnyPopoverVisible { return }

        NotificationCenter.default.post(name: .gameWindowDidHide, object: nil)
    }
    
    
    func windowWillClose(_ notification: Notification) {
        // SwiftUI 팝오버 또는 메인 팝오버가 열려 있으면 무시
        let isAnyPopoverVisible =
            (popover?.isShown ?? false) ||
            NSApp.windows.contains {
                String(describing: type(of: $0)).contains("NSPopoverWindow") && $0.isVisible
            }

        if isAnyPopoverVisible { return }

        NotificationCenter.default.post(name: .gameWindowDidHide, object: nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        // SwiftUI 팝오버 또는 메인 팝오버가 열려 있으면 무시
        let isAnyPopoverVisible =
            (popover?.isShown ?? false) ||
            NSApp.windows.contains {
                String(describing: type(of: $0)).contains("NSPopoverWindow") && $0.isVisible
            }

        if isAnyPopoverVisible { return }

        NotificationCenter.default.post(name: .gameWindowDidHide, object: nil)
    }
}

extension Notification.Name {
    static let gameWindowDidClose = Notification.Name("gameWindowDidClose")
    static let gameWindowDidHide = Notification.Name("gameWindowDidHide")
}
