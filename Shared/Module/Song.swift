//
//  Song.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import Foundation
import SwiftUI

struct Song: Hashable {
    var name: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var filePath: String
    var isSelected: Bool
    var isPlaying: Bool

    init() {
        name = ""
        artist = ""
        album = ""
        duration = TimeInterval(0)
        filePath = ""
        isSelected = false
        isPlaying = false
    }
}
