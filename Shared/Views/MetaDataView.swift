//
//  MetaDataView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/10.
//

import SwiftUI

struct MetaDataView: View {
//    @ObservedObject private var song: Song
//    @Binding private var isShowed = false
    @State var str = "test"
    var body: some View {
        VStack {
//                Form {
//                    TextField("歌曲名", text: song.name)
//                    TextField("专辑", text: song.album)
//                    TextField("艺术家", text: song.artist)
//
//                }
            TextField("歌曲名", text: $str)
            TextField("专辑", text: $str)
            TextField("艺术家", text: $str)
        }
        .zIndex(10)
    }
}

struct MetaDataView_Previews: PreviewProvider {
    static var previews: some View {
        MetaDataView()
    }
}
