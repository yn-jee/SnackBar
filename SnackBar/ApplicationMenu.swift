//
//  ApplicationMenu.swift
//  SnackBar
//
//  Created by 나윤지 on 4/13/25.
//

import Foundation
import SwiftUI

class ApplicationMenu: NSObject {
    static let shared = ApplicationMenu() // 싱글톤
    
    @ObservedObject var controller = MainViewController.shared
    var statusItem: NSStatusItem!
    var topView: NSHostingController<GameContainerView>?
    let popover = NSPopover()

    override init() {
        super.init()

        NotificationCenter.default.addObserver(forName: .gameDidChange, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let newSize = CGSize(width: self.controller.contentWidth, height: self.controller.totalHeight)
            print("창 크기 조정됨: \(newSize.width)")
//            self.topView?.view.frame.size = newSize
            self.popover.contentSize = newSize
        }
    }

    func attachToStatusBar(_ item: NSStatusItem) {
        self.statusItem = item
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.target = self
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            let gameContainer = GameContainerView()
            topView = NSHostingController(rootView: gameContainer)
            topView?.view.frame.size = CGSize(width: controller.contentWidth, height: self.controller.totalHeight)
            popover.contentViewController = NSViewController()
            popover.contentViewController?.view = topView!.view
            popover.behavior = .transient
            popover.contentSize = topView!.view.frame.size
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
