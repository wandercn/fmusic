//
//  Playlist.swift
//  Shared
//
//  Created by lsmiao on 2024/4/15.
//

import Foundation

/// 播放列表数据模型
struct Playlist: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var songs: [Song]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String, songs: [Song] = []) {
        self.id = id
        self.name = name
        self.songs = songs
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    mutating func addSong(_ song: Song) {
        // 避免重复添加
        if !songs.contains(where: { $0.filePath == song.filePath }) {
            songs.append(song)
            updatedAt = Date()
        }
    }
    
    mutating func addSongs(_ newSongs: [Song]) {
        for song in newSongs {
            addSong(song)
        }
    }
    
    mutating func removeSong(at index: Int) {
        guard index >= 0, index < songs.count else { return }
        songs.remove(at: index)
        updatedAt = Date()
    }
    
    mutating func removeSong(_ song: Song) {
        songs.removeAll(where: { $0.id == song.id })
        updatedAt = Date()
    }
    
    mutating func rename(to newName: String) {
        name = newName
        updatedAt = Date()
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}
