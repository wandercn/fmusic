//
//  FavoritesView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/20.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var favoritesList: [Song]
    @Binding var searchText: String

    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    // 列表显示搜索结果
    var searchResults: [Song] {
        if searchText.isEmpty {
            return favoritesList
        } else {
            return favoritesList.filter { x in
                x.name.contains(searchText) || x.album.contains(searchText) || x.artist.contains(searchText)
            }
        }
    }

    var body: some View {
        HStack {
            Group {
                ForEach(titles, id: \.self) { title in
                    Text(title)
                        .font(.headline) // 字C体
                        .fontWeight(.semibold) // 字体粗细
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, title == "歌曲名" ? 28 : 0)
                        .padding(.leading, title == "艺术家" ? 10 : 0)
                }
            }
        }
        .border(.gray, width: 0.5)
        .background(Color.white)
        .padding(.bottom, -9)

        List {
            ForEach(searchResults, id: \.self) { song in
                RowView(player: player, song: song)
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
    }
    //    func deleteItem(offsets: IndexSet){
    //        libraryList.remove(atOffsets: offsets)
    //    }
}

// struct FavoritesView_Previews: PreviewProvider {
//    static var previews: some View {
//        FavoritesView()
//    }
// }
