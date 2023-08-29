//
//  LyricsError.swift
//  SpotlightLyrics
//
//  Created by Scott Rong on 2017/7/28.
//  Copyright © 2017 Scott Rong. All rights reserved.
//

import Foundation

public class LyricsItem: Identifiable, Hashable {
    public static func == (lhs: LyricsItem, rhs: LyricsItem) -> Bool {
        lhs.id == rhs.id
    }

    public init(time: TimeInterval, text: String = "") {
        self.time = time
        self.text = text
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id = UUID()
    public var time: TimeInterval
    public var text: String
}
