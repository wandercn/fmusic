//
//  ListContentView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import AVFAudio
import SwiftUI

struct ListContentView: View {
    @ObservedObject var player: AudioPlayer
    @State private var showLibrary = true
    @State private var showPlayList = false
    @State private var showFavorites = false
    @State var searchText = ""
    @State private var favorites: [Song] = [Song()]
    var body: some View {
        NavigationView {
            List {
                Section(
                    header:
                    HStack {
                        Text("资料库")
                        Image(systemName: "flame.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                ) {
                    NavigationLink("歌曲", isActive: $showLibrary) {
                        LibraryView(
                            player: player,
                            searchText: $searchText
                        )
                    }.padding(.leading, 10)
                }
                .headerProminence(.increased)

                Section(
                    header: HStack {
                        Text("播放列表")
                        Image(systemName: "music.note.list")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                ) {
                    NavigationLink("所有播放列表", isActive: $showPlayList) {
                        List {
                            Text("播放列表1")
                            Text("播放列表2")
                        }

                    }.padding(.leading, 10)
                    NavigationLink("播放列表1") {
                        Text("歌曲1")
                        Text("歌曲1")
                    }.padding(.leading, 10)
                }
                .headerProminence(.increased)

                Section(
                    header: HStack {
                        Text("我的收藏")
                        Image(systemName: "suit.heart")
                    }
                    .font(.headline)
                    .foregroundColor(.purple)
                ) {
                    NavigationLink("我的收藏", isActive: $showFavorites) {
                        FavoritesView(player: player, favoritesList: $favorites, searchText: $searchText)
                            .task {
                                favorites = player.libraryList.filter { song in
                                    song.isHeartChecked == true
                                }
                            }
                    }.padding(.leading, 10)
                }
                .headerProminence(.increased)
                Spacer()
            }
            .searchable(text: $searchText, placement: .sidebar, prompt: "搜索")
            .navigationTitle("music")
            // 侧边搜索栏
        }
        .toolbar(content: {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    OpenSelectFolderWindws(player: player)
                }, label: {
                    Image(systemName: "folder.badge.plus")
                })
                Spacer()
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }

        })

        .navigationViewStyle(.columns)
    }
}

func toggleSidebar() {
    #if os(macOS)
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    #endif
}

struct SearchView: View {
    @Binding var searched: Bool
    @Binding var searchText: String
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment: .trailing) {
                    TextField("请输入搜索内容", text: $searchText)
                        .frame(width: 300)
                    Button {} label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                }
                Spacer()
            }
            Spacer()
        }
    }
}

struct LibraryView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var searchText: String

    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    // 列表显示搜索结果
    var searchResults: [Song] {
        if searchText.isEmpty {
            return player.libraryList
        } else {
            return player.libraryList.filter { x in
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

struct RowView: View {
    @ObservedObject var player: AudioPlayer
    @State var song: Song
    private let rowHeight = 20.0
    var body: some View {
        ZStack {
            HStack {
                Group {
                    Text(song.name)
                        .padding(.horizontal, 10)
                    Text(song.artist)
                    Text(song.album)
                    Text(durationFormat(timeInterval: song.duration))
                }
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
                .padding(.horizontal, 10)
            }

            HStack {
                if song.isPlaying {
                    Image(systemName: "livephoto.play")
                        .resizable()
                        .foregroundColor(song.isSelected ? Color.white : Color.red)
                        .frame(width: 20, height: rowHeight, alignment: .leading)
                        .scaledToFit()
                }

                Spacer()

                if song.isHeartChecked {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .foregroundColor(song.isPlaying ? Color.white : Color.red)
                        .frame(width: 20, height: rowHeight, alignment: .leading)
                        .scaledToFill()
                }
            }
        }
        .foregroundColor(song.isSelected ? Color.white : Color.black) // 前景颜色
        .buttonStyle(.borderless)
        .background(song.isSelected ? Color.purple : Color.clear)
        .itemBackgroundOnHover()
        .onTapGesture(count: 2) {
            flog.debug("onTapGesture2 .......")
            // 双击行切换歌曲播放
            player.currentSong = song
        }
        .onTapGesture(count: 1) {
            flog.debug("onTapGesture1 .......")
            // 选中行改变背景色
            if player.libraryList.count > 0 {
                for index in 0 ..< player.libraryList.count {
                    if player.libraryList[index].id == song.id {
                        player.libraryList[index].isSelected.toggle()
                        return
                    }
                }
            }
        }
    }
}

// 双击按钮
struct DoubleTapButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .gesture(TapGesture(count: 2).onEnded { configuration.trigger() })
    }
}
