//
//  Song.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation

struct Song :Hashable {
    var name: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var filePath: String
    var isSelected: Bool
    var isPlaying: Bool
    
}
