//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
    @Binding var currnetSong: Song
    @Binding var libraryList: [Song]
    var body: some View {
        ZStack {
            ListContentView(currnetSong: $currnetSong, libraryList: $libraryList)
            PlayerView(libraryList: $libraryList, currnetSong: $currnetSong)
        }

        .frame(minWidth: 800, minHeight: 600)
//        .onAppear {
//            if $libraryList.count > 0, currnetSong.filePath == "" {
//                for index in 0 ..< $libraryList.count {
//                    if libraryList[index].isPlaying {
//                        currnetSong = libraryList[index]
//                    }
//                }
//            }
//        }
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environment(\.sizeCategory, .extraSmall)
//    }
// }
