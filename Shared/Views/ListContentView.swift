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
    @Binding var isShowLyrics: Bool
    @State var searchText = ""
    @State private var selectedPlaylist: Int = -1  // -1 表示曲库，>=0 表示播放列表索引
    
    var body: some View {
        NavigationView {
            // 第一个视图：侧边栏
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

                // 播放列表管理
                Section(
                    header:
                    HStack {
                        Text("资料库")
                        Image(systemName: "flame.fill")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                ) {
                    PlaylistSidebarView(
                        player: player,
                        selectedPlaylist: $selectedPlaylist
                    )
                    .padding(.leading, 10)
                }

                // 已保存的目录列表
                if !player.savedDirectories.isEmpty {
                    Section(
                        header: HStack {
                            Text("已保存的目录 (\(player.savedDirectories.count))")
                            Image(systemName: "folder.fill")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    ) {
                        ForEach(Array(player.savedDirectories.enumerated()), id: \.offset) { index, dir in
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundColor(.blue)
                                Text(URL(fileURLWithPath: dir).lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Button(action: {
                                    player.removeDirectory(at: index)
                                    player.reloadAllSavedDirectories()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .help("移除该目录")
                            }
                            .padding(.vertical, 2)
                            .contextMenu {
                                Button(action: {
                                    NSWorkspace.shared.selectFile(dir, inFileViewerRootedAtPath: URL(fileURLWithPath: dir).deletingLastPathComponent().path)
                                }) {
                                    Text("在 Finder 中显示")
                                    Image(systemName: "folder")
                                }
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)

            // 第二个视图：主内容区域
            ZStack {
                if selectedPlaylist == -1 {
                    // 显示曲库
                    LibraryView(
                        player: player,
                        searchText: $searchText
                    )
                } else {
                    // 显示播放列表
                    PlaylistsView(
                        player: player,
                        searchText: $searchText
                    )
                }
            }
            .navigationTitle(selectedPlaylist == -1 ? "所有歌曲" : (selectedPlaylist < player.playlists.count ? player.playlists[selectedPlaylist].name : "播放列表"))
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: {
                    OpenSelectFolderWindws(player: player)
                }) {
                    Image(systemName: "plus.rectangle.on.folder")
                }
                .help("添加本地文件夹")

                Button(action: {
                    player.playList.removeAll()
                    player.Stop()
                }) {
                    Image(systemName: "trash")
                }
                .help("清空资料库")
                
                Spacer()
                
                Button(action: {
                    isShowLyrics.toggle()
                }) {
                    Image(systemName: "text.bubble")
                }
                .help(isShowLyrics ? "隐藏歌词" : "显示歌词")
            }
        }
    }
}

struct LibraryView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var searchText: String

    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    var searchResults: [Song] {
        if searchText.isEmpty {
            return player.playList
        } else {
            return player.playList.filter { x in
                x.name.localizedCaseInsensitiveContains(searchText) || 
                x.album.localizedCaseInsensitiveContains(searchText) || 
                x.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(titles, id: \.self) { title in
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, title == "歌曲名" ? 28 : 0)
                        .padding(.leading, title == "艺术家" ? 10 : 0)
                }
            }
            .border(Color.gray, width: 0.5)
            .background(Color.white)
            .padding(.bottom, -9)

            if searchResults.isEmpty {
                EmpetyListView()
            } else {
                List {
                    ForEach(searchResults, id: \.self) { song in
                        if let index = searchResults.firstIndex(of: song) {
                            RowView(player: player, song: song, index: index)
                        }
                    }
                }
            }
        }
    }
}

struct RowView: View {
    @ObservedObject var player: AudioPlayer
    @State var song: Song
    private let rowHeight = 20.0
    var index: Int
    @State var isShowMeta = false
    @State var isShowDetails = false

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
                .onTapGesture(count: 2) {
                    player.currentSong = song
                    player.playList = player.playList
                    player.isPlayingFromPlaylist = false
                }
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
                        .foregroundColor(song.isSelected ? Color.white : Color.red)
                        .frame(width: 20, height: rowHeight, alignment: .leading)
                        .scaledToFill()
                }
            }
        }
        .contextMenu {
            Button(action: { isShowMeta = true }) {
                Text("编辑元信息")
                Image(systemName: "square.and.pencil")
            }
            Button(action: { isShowDetails = true }) {
                Text("文件详情")
                Image(systemName: "info.circle")
            }
            
            Divider()
            
            // 使用显式的类型包装解决 macOS 11 下的 Menu 推断问题
            Menu("添加到播放列表") {
                ForEach(player.playlists, id: \.id) { playlist in
                    Button(action: {
                        if let pIndex = player.playlists.firstIndex(where: { $0.id == playlist.id }) {
                            player.addSongToPlaylist(song, playlistIndex: pIndex)
                        }
                    }) {
                        Text(playlist.name)
                    }
                }
                if player.playlists.isEmpty {
                    Text("暂无播放列表")
                }
            }
        }
        .sheet(isPresented: $isShowMeta) { MetaDataView(player: player, song: $song, isShowMeta: $isShowMeta) }
        .sheet(isPresented: $isShowDetails) { DetailsView(player: player, song: $song, isShowDetails: $isShowDetails) }
        .foregroundColor(song.isSelected ? Color.white : Color.black)
        .background(song.isSelected ? Color.purple : Color.clear)
        .background(index % 2 == 0 ? Color("lightGrey") : Color.clear)
        .itemBackgroundOnHover()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
    }
}
