//
//  musicApp.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation
import Logging
import SwiftUI
// 全局日志
var flog = Logger(label: "org.ffactory.fmusic")

@main
struct musicApp: App {
    @NSApplicationDelegateAdaptor(AboutDelegate.self) var aboutDelegate
    @StateObject var player = AudioPlayer()
    var body: some Scene {
        WindowGroup {
            ContentView(player: player)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            MainMenuView(player: player)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About fmusic") {
                    aboutDelegate.showAboutPanel()
                }
            }
        }
    }

    // 设置全局日志级别
    init() {
#if DEBUG
        flog.logLevel = .debug
#endif
    }
}
