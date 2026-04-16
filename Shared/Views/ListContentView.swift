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
    @Binding var isShowLyrics: Bool
    @State var searchText = ""
    @State private var favorites: [Song] = [Song()]
    
    // 用于管理播放列表的选中状态
    @State private var selectedPlaylist: Int? = -1 
    
    var body: some View {
        NavigationView {
            List {
                HStack {
                    TextField("搜索", text: $searchText)
                        .font(.headline)
                        .overlay(
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.gray)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 5)
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Section(
                    header: HStack {
                        Text("资料库")
                        Image(systemName: "flame.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                ) {
                    NavigationLink(destination: LibraryView(player: player, searchText: $searchText), tag: -1, selection: $selectedPlaylist) {
                        Label("所有歌曲", systemImage: "music.note.list")
                    }
                    .padding(.leading, 10)
                }

                Section(
                    header: HStack {
                        Text("我的收藏")
                        Image(systemName: "suit.heart")
                    }
                    .font(.headline)
                    .foregroundColor(.purple)
                ) {
                    NavigationLink(destination: FavoritesView(player: player, searchText: $searchText), tag: -2, selection: $selectedPlaylist) {
                        Label("我的收藏", systemImage: "heart.fill")
                    }
                    .padding(.leading, 10)
                }

                Section(
                    header: HStack {
                        Text("播放列表")
                        Image(systemName: "music.note.list")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                ) {
                    PlaylistSidebarView(player: player, selectedPlaylist: $selectedPlaylist)
                        .padding(.leading, 10)
                }

                if !player.savedDirectories.isEmpty {
                    Section(header: Text("已保存的目录").foregroundColor(.blue)) {
                        ForEach(Array(player.savedDirectories.enumerated()), id: \.offset) { index, dir in
                            HStack {
                                Image(systemName: "folder").foregroundColor(.blue)
                                Text(URL(fileURLWithPath: dir).lastPathComponent).lineLimit(1)
                                Spacer()
                                Button(action: { player.removeDirectory(at: index); player.reloadAllSavedDirectories() }) {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("移除此目录")
                            }
                            .contextMenu {
                                Button(action: { NSWorkspace.shared.selectFile(dir, inFileViewerRootedAtPath: URL(fileURLWithPath: dir).deletingLastPathComponent().path) }) {
                                    Text("在 Finder 中显示")
                                }
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 200)

            // 动态详情视图
            detailView
        }
        .navigationTitle("music")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { OpenSelectFolderWindws(player: player) }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("导入音乐文件夹")
                .pinkBackgroundOnHover()

                Button(action: { player.librarySongs.removeAll(); player.Stop() }) {
                    Image(systemName: "trash")
                }
                .help("清空资料库")
                .pinkBackgroundOnHover()

                Spacer()
                Button(action: { isShowLyrics.toggle() }) {
                    Image(systemName: "text.bubble")
                }
                .help(isShowLyrics ? "隐藏歌词" : "显示歌词")
                .pinkBackgroundOnHover()
            }
        }
        .navigationViewStyle(.automatic)
    }

    @ViewBuilder
    private var detailView: some View {
        if let selection = selectedPlaylist {
            if selection == -1 {
                LibraryView(player: player, searchText: $searchText)
            } else if selection == -2 {
                FavoritesView(player: player, searchText: $searchText)
            } else if selection >= 0 && selection < player.playlists.count {
                PlaylistsView(player: player, searchText: $searchText, playlistIndex: selection)
            } else {
                LibraryView(player: player, searchText: $searchText)
            }
        } else {
            LibraryView(player: player, searchText: $searchText)
        }
    }
}

struct LibraryView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var searchText: String

    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    var searchResults: [Song] {
        if searchText.isEmpty { return player.librarySongs }
        return player.librarySongs.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText) }
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
        .navigationTitle("所有歌曲")
    }
}

struct RowView: View {
    @ObservedObject var player: AudioPlayer
    @State var song: Song
    var index: Int
    var queue: [Song]
    @State var isShowMeta = false
    @State var isShowDetails = false

    var body: some View {
        ZStack {
            HStack {
                Group {
                    Text(song.name).padding(.horizontal, 10)
                    Text(song.artist)
                    Text(song.album)
                    Text(durationFormat(timeInterval: song.duration))
                }
                .lineLimit(1)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .onTapGesture(count: 2) { player.play(song: song, in: queue) }
            }

            if player.currentSong.filePath == song.filePath {
                HStack {
                    Image(systemName: "livephoto.play")
                        .resizable()
                        .foregroundColor(song.isSelected ? .white : .red)
                        .frame(width: 20, height: 20)
                    Spacer()
                }
            }
        }
        .contextMenu {
            Button(action: { isShowMeta = true }) { Text("编辑元信息") }
            Button(action: { isShowDetails = true }) { Text("文件详情") }
            Divider()
            Menu("添加到播放列表") {
                ForEach(Array(player.playlists.enumerated()), id: \.offset) { pIndex, playlist in
                    Button(playlist.name) { player.addSongToPlaylist(song, playlistIndex: pIndex) }
                }
            }
        }
        .sheet(isPresented: $isShowMeta) { MetaDataView(player: player, song: $song, isShowMeta: $isShowMeta) }
        .sheet(isPresented: $isShowDetails) { DetailsView(player: player, song: $song, isShowDetails: $isShowDetails) }
        .foregroundColor(song.isSelected ? Color.white : Color.black)
        .background(song.isSelected ? Color.purple : Color.clear)
        .background(index % 2 == 0 ? Color("lightGrey") : Color.clear)
        .itemBackgroundOnHover()
    }
}
