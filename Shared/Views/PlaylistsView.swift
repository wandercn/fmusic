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
    
    let titles = ["歌曲名", "艺术家", "专辑", "时长"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 表头
            HStack {
                Group {
                    ForEach(titles, id: \.self) { title in
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, title == "歌曲名" ? 28 : 0)
                            .padding(.leading, title == "艺术家" ? 10 : 0)
                    }
                }
            }
            .border(Color.gray, width: 0.5)
            .background(Color.white)
            .padding(.bottom, -9)
            
            // 歌曲列表
            if player.activePlayList.isEmpty {
                EmpetyListView()
            } else {
                List {
                    ForEach(player.activePlayList, id: \.self) { song in
                        if let index = player.activePlayList.firstIndex(of: song) {
                            PlaylistRowView(player: player, song: song, index: index, playlistIndex: player.currentPlaylistIndex)
                        }
                    }
                }
            }
        }
    }
}

/// 播放列表行视图（支持从播放列表删除）
struct PlaylistRowView: View {
    @ObservedObject var player: AudioPlayer
    @State var song: Song
    private let rowHeight = 20.0
    var index: Int
    @State var isShowMeta = false
    @State var isShowDetails = false
    var playlistIndex: Int  // 所属播放列表的索引
    
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
                    flog.debug("双击播放歌曲: \(song.name)")
                    playFromPlaylist()
                }
                .onTapGesture(count: 1) {
                    flog.debug("选中歌曲")
                    if player.activePlayList.count > 0 {
                        for i in 0 ..< player.activePlayList.count {
                            if player.activePlayList[i].id == song.id {
                                player.activePlayList[i].isSelected.toggle()
                                return
                            }
                        }
                    }
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
            Button {
                isShowMeta = true
            } label: {
                HStack {
                    Text("编辑元信息")
                    Image(systemName: "square.and.pencil")
                }
            }
            Button {
                isShowDetails = true
            } label: {
                HStack {
                    Text("文件详情")
                    Image(systemName: "info.circle")
                }
            }
            
            Divider()
            
            Button {
                removeFromPlaylist()
            } label: {
                HStack {
                    Text("从播放列表移除")
                    Image(systemName: "minus.circle")
                }
            }
        }
        .sheet(isPresented: $isShowMeta, content: {
            MetaDataView(player: player, song: $song, isShowMeta: $isShowMeta)
        })
        .sheet(isPresented: $isShowDetails, content: {
            DetailsView(player: player, song: $song, isShowDetails: $isShowDetails)
        })
        .foregroundColor(song.isSelected ? Color.white : Color.black)
        .background(song.isSelected ? Color.purple : Color.clear)
        .background(index % 2 == 0 ? Color("lightGrey") : Color.clear)
        .itemBackgroundOnHover()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
    }
    
    private func playFromPlaylist() {
        player.currentSong = song
        player.playList = player.activePlayList
        player.isPlayingFromPlaylist = true
    }
    
    private func removeFromPlaylist() {
        guard playlistIndex >= 0 else { return }
        player.removeSongFromPlaylist(playlistIndex: playlistIndex, songIndex: index)
        player.selectPlaylist(at: playlistIndex)
    }
}

/// 侧边栏播放列表管理视图
struct PlaylistSidebarView: View {
    @ObservedObject var player: AudioPlayer
    @Binding var selectedPlaylist: Int
    @State private var showingCreateSheet = false
    @State private var editingIndex: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 曲库入口
            Button(action: {
                player.selectLibrary()
                selectedPlaylist = -1
            }) {
                Label("歌曲", systemImage: "music.note.list")
            }
            .buttonStyle(.borderless)
            .foregroundColor(selectedPlaylist == -1 ? .accentColor : .primary)
            
            Divider()
            
            // 播放列表标题
            HStack {
                Text("播放列表")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    showingCreateSheet = true
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("创建新播放列表")
            }
            .padding(.horizontal, 5)
            
            // 播放列表列表
            ForEach(Array(player.playlists.enumerated()), id: \.offset) { index, playlist in
                SidebarPlaylistItemView(
                    player: player,
                    index: index,
                    playlist: playlist,
                    selectedPlaylist: $selectedPlaylist,
                    editingIndex: $editingIndex
                )
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            PlaylistEditSheet(title: "创建播放列表", name: "") { name in
                let _ = player.createPlaylist(name: name)
                showingCreateSheet = false
            } onCancel: {
                showingCreateSheet = false
            }
        }
        .sheet(isPresented: Binding(
            get: { editingIndex != nil },
            set: { if !$0 { editingIndex = nil } }
        )) {
            if let index = editingIndex {
                PlaylistEditSheet(title: "重命名播放列表", name: player.playlists[index].name) { name in
                    player.renamePlaylist(at: index, newName: name)
                    editingIndex = nil
                } onCancel: {
                    editingIndex = nil
                }
            }
        }
    }
}

/// 单个播放列表项（解决编译超时）
struct SidebarPlaylistItemView: View {
    @ObservedObject var player: AudioPlayer
    let index: Int
    let playlist: Playlist
    @Binding var selectedPlaylist: Int
    @Binding var editingIndex: Int?
    
    var body: some View {
        HStack {
            Button(action: {
                player.selectPlaylist(at: index)
                selectedPlaylist = index
            }) {
                HStack {
                    Image(systemName: selectedPlaylist == index ? "music.playlist.fill" : "music.playlist")
                        .foregroundColor(selectedPlaylist == index ? .accentColor : .secondary)
                    Text(playlist.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text("(\(playlist.songs.count))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.borderless)
            .foregroundColor(selectedPlaylist == index ? .accentColor : .primary)
            
            // 删除按钮
            Button(action: {
                player.deletePlaylist(at: index)
                if selectedPlaylist == index {
                    selectedPlaylist = -1
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("删除播放列表")
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button {
                editingIndex = index
            } label: {
                Label("重命名", systemImage: "pencil")
            }
            
            Button {
                player.deletePlaylist(at: index)
                if selectedPlaylist == index {
                    selectedPlaylist = -1
                }
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

/// 播放列表编辑弹窗（兼容 macOS 11）
struct PlaylistEditSheet: View {
    let title: String
    @State var name: String
    var onSave: (String) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
            
            TextField("播放列表名称", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)
            
            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("确定") {
                    onSave(name)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
