//
//  Song.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation
import SwiftUI

struct Song: Identifiable, Hashable, Codable {
    let id = UUID()

    var name: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var filePath: String
    var isSelected: Bool
    var isPlaying: Bool
    var isHeartChecked: Bool
    var track: Int

    init() {
        name = ""
        artist = ""
        album = ""
        duration = TimeInterval(0)
        filePath = ""
        isSelected = false
        isPlaying = false
        isHeartChecked = false
        track = 0
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case name, artist, album, duration, filePath, isSelected, isPlaying, isHeartChecked, track
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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
