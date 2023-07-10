//
//  musicApp.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

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
}
