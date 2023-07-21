//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var player: AudioPlayer
    var body: some View {
        ZStack {
            ListContentView(player: player)
            PlayerView(player: player)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(player: AudioPlayer(path: "/Users/lsmiao/Music/ACC音乐"))
                .environment(\.sizeCategory, .extraSmall)
        }
    }
}
