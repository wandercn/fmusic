//
//  Song.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation
import SwiftUI

struct Song: Identifiable, Hashable {
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
}
