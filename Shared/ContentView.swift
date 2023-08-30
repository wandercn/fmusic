//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var player: AudioPlayer
    @State var isShowLyrics: Bool = false
    var body: some View {
        HSplitView {
            ZStack {
                ListContentView(player: player, isShowLyrics: $isShowLyrics)
                PlayerView(player: player)
            }
            .frame(minWidth: 800, minHeight: 600)
            if isShowLyrics {
                LyricsView(player: player)
            }
        }
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
