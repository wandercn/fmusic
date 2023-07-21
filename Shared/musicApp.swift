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
    @StateObject var player = AudioPlayer()
    var body: some Scene {
        WindowGroup {
            ContentView(player: player)
        }
        .commands {
            MainMenuView(player: player)
        }
    }

    // 设置全局日志级别
    init() {
#if DEBUG
        flog.logLevel = .debug
#endif
    }
}
