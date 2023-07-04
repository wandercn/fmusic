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
  var body: some Scene {
    WindowGroup {
      ContentView(libraryList: self.$libraryList)
    }
    .commands {
      MainMenuView(libraryList: self.$libraryList)
    }

  }
}
