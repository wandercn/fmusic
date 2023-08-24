//
//  AboutDelegate.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/23.
//

import Cocoa
import SwiftUI

class AboutDelegate: NSObject, NSApplicationDelegate {
    private var aboutBoxWindowController: NSWindowController?

    func showAboutPanel() {
        if aboutBoxWindowController == nil {
            let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, /* .resizable,*/ .titled]
            let window = NSWindow()
            window.styleMask = styleMask
            window.title = "About fmusic"
            window.contentView = NSHostingView(rootView: AboutView())
            window.center()
            aboutBoxWindowController = NSWindowController(window: window)
        }

        aboutBoxWindowController?.showWindow(aboutBoxWindowController?.window)
    }
}
public extension Bundle {
    var appName: String { getInfo("CFBundleName") }
    var copyright: String { getInfo("NSHumanReadableCopyright") }

    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    private func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
