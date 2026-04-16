//
//  Song.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation
import SwiftUI

struct Song: Identifiable, Hashable, Codable {
    let id: UUID

    var name: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var filePath: String
    var isSelected: Bool
    var isPlaying: Bool
    var isHeartChecked: Bool
    var track: Int

    init(id: UUID = UUID(), name: String = "", artist: String = "", album: String = "", duration: TimeInterval = 0, filePath: String = "", isSelected: Bool = false, isPlaying: Bool = false, isHeartChecked: Bool = false, track: Int = 0) {
        self.id = id
        self.name = name
        self.artist = artist
        self.album = album
        self.duration = duration
        self.filePath = filePath
        self.isSelected = isSelected
        self.isPlaying = isPlaying
        self.isHeartChecked = isHeartChecked
        self.track = track
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, artist, album, duration, filePath, isSelected, isPlaying, isHeartChecked, track
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        artist = try container.decode(String.self, forKey: .artist)
        album = try container.decode(String.self, forKey: .album)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        filePath = try container.decode(String.self, forKey: .filePath)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        isPlaying = try container.decode(Bool.self, forKey: .isPlaying)
        isHeartChecked = try container.decode(Bool.self, forKey: .isHeartChecked)
        track = try container.decode(Int.self, forKey: .track)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(duration, forKey: .duration)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isPlaying, forKey: .isPlaying)
        try container.encode(isHeartChecked, forKey: .isHeartChecked)
        try container.encode(track, forKey: .track)
    }
}
