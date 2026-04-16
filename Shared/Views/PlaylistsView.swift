//
//  PlaylistsView.swift
//  Shared
//
//  Created by lsmiao on 2024/4/15.
//

import SwiftUI

/// 播放列表视图
struct PlaylistsView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var searchText: String
    var playlistIndex: Int
    
    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    
    var body: some View {
        let songs = playlistIndex >= 0 && playlistIndex < player.playlists.count ? player.playlists[playlistIndex].songs : []
        let filteredSongs = searchText.isEmpty ? songs : songs.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.artist.localizedCaseInsensitiveContains(searchText) }

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

            if filteredSongs.isEmpty {
                EmpetyListView()
            } else {
                List {
                    ForEach(Array(filteredSongs.enumerated()), id: \.offset) { index, song in
                        PlaylistRowView(player: player, song: song, index: index, playlistIndex: playlistIndex, queue: filteredSongs)
                    }
                }
            }
        }
        .background(Color.white)
        .navigationTitle(playlistIndex >= 0 && playlistIndex < player.playlists.count ? player.playlists[playlistIndex].name : "播放列表")
    }
}

/// 播放列表行视图
struct PlaylistRowView: View {
    @ObservedObject var player: AudioPlayer
    @State var song: Song
    var index: Int
    var playlistIndex: Int
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
                    Image(systemName: "livephoto.play").resizable().foregroundColor(song.isSelected ? .white : .red).frame(width: 20, height: 20)
                    Spacer()
                }
            }
        }
        .contextMenu {
            Button(action: { isShowMeta = true }) { Text("编辑元信息") }
            Button(action: { isShowDetails = true }) { Text("文件详情") }
            Divider()
            Button(action: { player.removeSongFromPlaylist(playlistIndex: playlistIndex, songIndex: index) }) { Text("从播放列表移除") }
        }
        .sheet(isPresented: $isShowMeta) { MetaDataView(player: player, song: $song, isShowMeta: $isShowMeta) }
        .sheet(isPresented: $isShowDetails) { DetailsView(player: player, song: $song, isShowDetails: $isShowDetails) }
        .foregroundColor(song.isSelected ? Color.white : Color.black)
        .background(song.isSelected ? Color.purple : Color.clear)
        .background(index % 2 == 0 ? Color("lightGrey") : Color.clear)
        .itemBackgroundOnHover()
    }
}

/// 侧边栏播放列表管理视图
struct PlaylistSidebarView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var selectedPlaylist: Int?
    @Binding var showingCreateSheet: Bool
    @Binding var searchText: String
    @State private var editingIndex: Int? = nil
    
    var body: some View {
        // 移除了 VStack，让 ForEach 的子项直接作为 List 的行展开
        ForEach(Array(player.playlists.enumerated()), id: \.offset) { index, playlist in
            SidebarPlaylistItemView(player: player, index: index, playlist: playlist, selectedPlaylist: $selectedPlaylist, editingIndex: $editingIndex, searchText: $searchText)
        }
        .sheet(isPresented: $showingCreateSheet) {
            PlaylistEditSheet(title: "创建播放列表", name: "") { name in
                _ = player.createPlaylist(name: name)
                showingCreateSheet = false
            } onCancel: { showingCreateSheet = false }
        }
        .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
            if let index = editingIndex {
                PlaylistEditSheet(title: "重命名播放列表", name: player.playlists[index].name) { name in
                    player.renamePlaylist(at: index, newName: name)
                    editingIndex = nil
                } onCancel: { editingIndex = nil }
            }
        }
    }
}

struct SidebarPlaylistItemView: View {
    @ObservedObject var player: AudioPlayer
    let index: Int
    let playlist: Playlist
    @Binding var selectedPlaylist: Int?
    @Binding var editingIndex: Int?
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            // 使用 NavigationLink 替代 Button 获得系统原生选中样式
            NavigationLink(
                destination: PlaylistsView(player: player, searchText: $searchText, playlistIndex: index),
                tag: index,
                selection: $selectedPlaylist
            ) {
                HStack {
                    Image(systemName: selectedPlaylist == index ? "music.playlist.fill" : "music.playlist")
                    Text(playlist.name).font(.subheadline).lineLimit(1)
                    Text("(\(playlist.songs.count))").font(.caption2).opacity(0.8)
                    Spacer()
                }
            }
            
            Button(action: { player.deletePlaylist(at: index); if selectedPlaylist == index { selectedPlaylist = nil } }) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption)
            }
            .buttonStyle(BorderlessButtonStyle())
            .help("删除播放列表")
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(action: { editingIndex = index }) { Text("重命名") }
            Button(action: { player.deletePlaylist(at: index); if selectedPlaylist == index { selectedPlaylist = nil } }) { Text("删除") }
        }
    }
}

struct PlaylistEditSheet: View {
    let title: String
    @State var name: String
    var onSave: (String) -> Void
    var onCancel: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text(title).font(.headline)
            TextField("播放列表名称", text: $name).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 250)
            HStack {
                Button("取消") { onCancel() }.keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("确定") { onSave(name) }.keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding().frame(width: 300)
    }
}
