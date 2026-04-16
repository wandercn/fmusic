//
//  FavoritesView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/20.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var searchText: String

    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    
    // 过滤出所有已收藏的歌曲
    var favorites: [Song] {
        player.librarySongs.filter { $0.isHeartChecked }
    }
    
    // 列表显示搜索结果
    var searchResults: [Song] {
        if searchText.isEmpty {
            return favorites
        } else {
            return favorites.filter { x in
                x.name.localizedCaseInsensitiveContains(searchText) || 
                x.album.localizedCaseInsensitiveContains(searchText) || 
                x.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Group {
                    ForEach(titles, id: \.self) { title in
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, title == "歌曲名" ? 28 : (title == "艺术家" ? 10 : 0))
                    }
                }
            }
            .border(Color.gray, width: 0.5)
            .background(Color.white)
            .padding(.bottom, -1)

            if searchResults.isEmpty {
                EmpetyListView()
            } else {
                List {
                    ForEach(searchResults, id: \.filePath) { song in
                        if let index = searchResults.firstIndex(where: { $0.filePath == song.filePath }) {
                            RowView(player: player, song: song, index: index, queue: searchResults)
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .navigationTitle("我的收藏")
    }
}
