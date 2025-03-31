//
//  LyricsError.swift
//  SpotlightLyrics
//
//  Created by Scott Rong on 2017/7/28.
//  Copyright © 2017 Scott Rong. All rights reserved.
//

import Foundation

// --- 新增：表示单个字/词及其时间信息的结构体 ---
public struct WordInfo: Identifiable, Hashable {
    public var id = UUID() // 每个字/词一个唯一 ID
    public var word: String // 单个字或词
    public var startTime: TimeInterval // 相对于该行歌词开始的时间偏移 (秒)
    public var duration: TimeInterval // 该字/词持续的时间 (秒)

    public init(word: String, startTime: TimeInterval, duration: TimeInterval) {
        self.word = word
        self.startTime = startTime
        self.duration = duration
    }

    // 实现 Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // 实现 Equatable (基于 ID)
    public static func == (lhs: WordInfo, rhs: WordInfo) -> Bool {
        lhs.id == rhs.id
    }
}

public class LyricsItem: Identifiable, Hashable {
    public static func == (lhs: LyricsItem, rhs: LyricsItem) -> Bool {
        lhs.id == rhs.id
    }

    public init(time: TimeInterval, text: String = "", wordInfos: [WordInfo]? = nil) {
        self.time = time
        self.text = text // 保留整句文本，方便不显示卡拉OK效果时使用
        self.wordInfos = wordInfos ?? [] // 初始化 wordInfos
        self.id = UUID()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public var id: UUID
    public var time: TimeInterval
    public var text: String
    public var wordInfos: [WordInfo] = []
    public var plainText: String { // 计算属性获取纯文本
        wordInfos.isEmpty ? text : wordInfos.map(\.word).joined()
    }
}
