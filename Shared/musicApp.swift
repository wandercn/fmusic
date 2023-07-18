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
    @State var libraryList: [Song] = []
    @State var currnetSong: Song = .init()
    var body: some Scene {
        WindowGroup {
            ContentView(currnetSong: $currnetSong, libraryList: $libraryList)
        }
        .commands {
            MainMenuView(libraryList: $libraryList)
        }
    }

    // 设置全局日志级别
    init() { flog.logLevel = .info
    }
}
