//
//  LyricsParser.swift
//  SpotlightLyrics
//
//  Created by Scott Rong on 2017/4/2.
//  Copyright © 2017 Scott Rong. All rights reserved.
//

import Foundation

public protocol LyricsManagerDelegate: AnyObject {
    func occoursError(error: Error)
}

public class LyricsParser {
    public var header: LyricsHeader
    public var lyrics: [LyricsItem] = []
    public var autor: String = ""

    // MARK: Initializers

    public init() {
        header = LyricsHeader()
        lyrics = []
    }

    public init(lyrics: String) {
        header = LyricsHeader()
        commonInit(lyrics: lyrics)
    }

    private func commonInit(lyrics: String) {
        header = LyricsHeader()
        parse(lyrics: lyrics)
    }

    // 临时的结构体，用于存储解析过程中的中间数据
    private struct ParsedLineInfo {
        var time: TimeInterval
        var text: String? // 普通歌词文本
        var ttContent: String? // [tt] 标签后的内容 <time,index>...
    }

    /// 新的解析方法，处理关联行和 [tt] 标签
    private func parse(lyrics: String) {
        let lines = lyrics
            .replacingOccurrences(of: "\\n", with: "\n")
            .components(separatedBy: .newlines)

        // 1. 第一次遍历：解析头部信息，并将普通歌词和 [tt] 行按时间戳分组
        var lineInfosByTime = [TimeInterval: ParsedLineInfo]()

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }

            // 尝试解析头部
            if parseHeaderLine(line: trimmedLine) { continue }

            // 尝试解析时间和内容类型 (普通文本 或 [tt] 内容)
            if let (timeValue, content, isTTLine) = parseBasicLyricLine(line: trimmedLine) {
                let finalTime = timeValue + header.offset // 应用全局偏移

                // 获取或创建该时间戳的 ParsedLineInfo
                var info = lineInfosByTime[finalTime, default: ParsedLineInfo(time: finalTime)]

                if isTTLine {
                    // 如果是 [tt] 行，存储其内容
                    if info.ttContent == nil { // 防止重复覆盖
                        info.ttContent = content
                        // flog.debug("Found TT content for time \(finalTime): \(content)")
                    } else {
//                        flog.debug("Duplicate TT content found for time \(finalTime), keeping first.")
                    }
                } else {
                    // 如果是普通歌词行，存储其文本
                    if info.text == nil { // 防止重复覆盖
                        info.text = content
                        // flog.debug("Found Text content for time \(finalTime): \(content)")
                    } else {
//                        flog.debug("Duplicate Text content found for time \(finalTime), keeping first.")
                    }
                }
                // 更新字典
                lineInfosByTime[finalTime] = info
            } else {
                flog.debug("Skipping unparsable line: \(trimmedLine)")
            }
        }

        // 2. 第二次遍历：合并信息，生成最终的 LyricsItem 列表
        var finalLyrics: [LyricsItem] = []
        // 按时间排序字典的键
        let sortedTimes = lineInfosByTime.keys.sorted()

        for time in sortedTimes {
            if let info = lineInfosByTime[time] {
                // 检查是否有普通文本
                guard let text = info.text, !text.isEmpty else {
                    // flog.debug("Skipping line at time \(time) due to missing text content.")
                    continue // 如果没有歌词文本，通常跳过这一行
                }

                var wordInfos: [WordInfo] = []
                // 如果有关联的 [tt] 内容，解析它来生成 wordInfos
                if let ttContent = info.ttContent {
                    wordInfos = parseTTContent(textContent: text, ttContent: ttContent)
                }

                // 如果解析 [tt] 失败或没有 [tt] 内容，可以选择创建一个包含整句的 WordInfo
                if wordInfos.isEmpty {
                    // 创建一个覆盖整行的 WordInfo (可选，取决于是否要在无逐字信息时模拟)
//                    let approxDuration = (lineInfosByTime.keys.sorted().first(where: { $0 > time }) ?? (time + 5)) - time // 估算时长
//                    wordInfos.append(WordInfo(word: text, startTime: 0, duration: approxDuration > 0 ? approxDuration : 1.0))
//                    flog.debug("No valid word info parsed for line at time \(time), using plain text.")
                }

                // 创建最终的 LyricsItem
                let lyricsItem = LyricsItem(time: time, text: text, wordInfos: wordInfos)
                finalLyrics.append(lyricsItem)
            }
        }

        self.lyrics = finalLyrics // 赋值给最终的 lyrics 数组
        // (可选) 将头部信息作为特殊歌词行插入开头 (如果需要的话)
        // insertHeaderAsLyrics() // 之前的实现可能需要调整以适应新的结构
        flog.debug("Lyrics parsing finished. Total final lines: \(self.lyrics.count)")
    }

    /// 解析基础歌词行，返回 (时间, 内容, 是否为TT行)
    /// 内容是时间戳之后的部分
    private func parseBasicLyricLine(line: String) -> (TimeInterval, String, Bool)? {
        // 匹配时间戳 [mm:ss.xx] 或 [mm:ss:xx]
        let timeTagRegex = try! NSRegularExpression(pattern: #"^\[(\d{2,}):(\d{2})([.:]\d{1,3})?\]"#)
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)

        if let match = timeTagRegex.firstMatch(in: line, options: [], range: nsRange) {
            // 提取时间字符串
            if let timeStrRange = Range(match.range(at: 0), in: line) {
                let timePartStr = String(line[line.index(timeStrRange.lowerBound, offsetBy: 1)..<line.index(timeStrRange.upperBound, offsetBy: -1)])

                // 解析时间值
                if let timeValue = parseTimeTag(timeString: timePartStr) {
                    // 获取时间戳后面的内容
                    let contentStartIndex = timeStrRange.upperBound
                    let content = String(line[contentStartIndex...]).trimmingCharacters(in: .whitespaces)

                    // 检查内容是否以 "[tt]" 开头
                    if content.hasPrefix("[tt]") {
                        // 提取 [tt] 之后的内容
                        let ttContentStartIndex = content.index(content.startIndex, offsetBy: 4) // 移动到 "[tt]" 之后
                        let ttContent = String(content[ttContentStartIndex...])
                        return (timeValue, ttContent, true) // 返回时间、TT内容、标记为TT行
                    } else {
                        // 是普通歌词行
                        return (timeValue, content, false) // 返回时间、歌词文本、标记为非TT行
                    }
                } else {
                    flog.error("Failed to parse time tag: \(timePartStr) in line: \(line)")
                }
            }
        }
        return nil // 无法解析为基础歌词行
    }

    /// 解析 [tt] 行内容，生成 WordInfo 数组
    /// textContent: 对应的普通歌词行的纯文本
    /// ttContent: [tt] 标签后的内容，例如 "<0,0><337,1><674,2>..."
    private func parseTTContent(textContent: String, ttContent: String) -> [WordInfo] {
        // 1. 解析 ttContent 中的 <startTime,wordIndex> 标签
        let ttTagRegex = try! NSRegularExpression(pattern: #"<(-?\d+),(\d+)>"#)
        let nsRange = NSRange(ttContent.startIndex..<ttContent.endIndex, in: ttContent)
        let matches = ttTagRegex.matches(in: ttContent, range: nsRange)

        // 存储解析出的 (开始时间毫秒, 单词索引) 对
        var timeIndexPairs: [(startTimeMs: Int, wordIndex: Int)] = []
        for match in matches {
            if match.numberOfRanges == 3,
               let startMsRange = Range(match.range(at: 1), in: ttContent),
               let indexRange = Range(match.range(at: 2), in: ttContent),
               let startTimeMs = Int(ttContent[startMsRange]),
               let wordIndex = Int(ttContent[indexRange])
            {
                timeIndexPairs.append((startTimeMs, wordIndex))
            } else {
                flog.error("Failed to parse TT tag in content: \(ttContent)")
            }
        }

        // 如果没有解析到有效的 TT 标签，返回空数组
        guard !timeIndexPairs.isEmpty else {
            flog.debug("No valid TT tags found in: \(ttContent)")
            return []
        }

        // 2. 按开始时间排序
        timeIndexPairs.sort { $0.startTimeMs < $1.startTimeMs }

        // 3. 将 textContent 转换为字符数组 (处理 Unicode)
        let characters = Array(textContent)

        // 4. 生成 WordInfo 数组
        var wordInfos: [WordInfo] = []
        for i in 0..<timeIndexPairs.count {
            let currentPair = timeIndexPairs[i]
            let startTimeMs = currentPair.startTimeMs
            let wordIndex = currentPair.wordIndex // 这个索引对应 characters 数组

            // 确保 wordIndex 有效
            guard wordIndex >= 0, wordIndex < characters.count else {
                flog.error("Invalid wordIndex \(wordIndex) for text length \(characters.count) from TT tag <\(startTimeMs),\(wordIndex)>")
                continue
            }

            // 获取当前字符
            let word = String(characters[wordIndex])

            // 计算持续时间：使用下一个标签的开始时间，或者行尾的估算时间
            let nextStartTimeMs: Int
            if i + 1 < timeIndexPairs.count {
                nextStartTimeMs = timeIndexPairs[i + 1].startTimeMs
            } else {
                // 对于最后一个字，估算一个持续时间，例如 500ms 或根据需要调整
                nextStartTimeMs = startTimeMs + 500 // 默认 500ms 持续时间
                // 也可以尝试根据歌曲总时长和歌词行数估算平均时长，但可能不准
            }

            // 持续时间不能为负数
            let durationMs = max(0, nextStartTimeMs - startTimeMs)

            // 转换为秒
            let startTimeSec = TimeInterval(startTimeMs) / 1000.0
            let durationSec = TimeInterval(durationMs) / 1000.0

            // 创建 WordInfo
            wordInfos.append(WordInfo(word: word, startTime: startTimeSec, duration: durationSec))
        }

        flog.debug("Parsed \(wordInfos.count) WordInfo objects from TT content.")
        return wordInfos
    }

    // --- 其他方法 (parseHeaderLine, parseHeaderTag, parseTimeTag, parseComponent, insertHeaderAsLyrics) ---
    // 这些方法基本保持不变，但 parseTimeTag 和 parseComponent 已包含在上方

    /// 解析头部信息行，如果成功返回 true (保持不变)
    private func parseHeaderLine(line: String) -> Bool {
        if let title = parseHeaderTag(prefix: "ti", line: line) { header.title = title; return true }
        if let author = parseHeaderTag(prefix: "ar", line: line) { header.author = author; return true }
        if let album = parseHeaderTag(prefix: "al", line: line) { header.album = album; return true }
        if let by = parseHeaderTag(prefix: "by", line: line) { header.by = by; return true }
        if let offsetStr = parseHeaderTag(prefix: "offset", line: line), let offsetVal = TimeInterval(offsetStr) {
            header.offset = offsetVal / 1000.0 // 毫秒转秒
            flog.debug("Parsed offset: \(offsetVal)ms -> \(header.offset)s")
            return true
        }
        if let lengthStr = parseHeaderTag(prefix: "length", line: line), let length = TimeInterval(lengthStr) {
            header.longSec = length
            return true
        }
        if let editor = parseHeaderTag(prefix: "re", line: line) { header.editor = editor; return true }
        if let version = parseHeaderTag(prefix: "ve", line: line) { header.version = version; return true }
        if line.hasPrefix("[:]") { return true } // 忽略空标签
        return false
    }

    /// 从行中提取头部标签的值 (保持不变)
    private func parseHeaderTag(prefix: String, line: String) -> String? {
        let tagOpen = "[" + prefix + ":"
        if line.hasPrefix(tagOpen), line.hasSuffix("]") {
            let startIndex = line.index(line.startIndex, offsetBy: tagOpen.count)
            let endIndex = line.index(line.endIndex, offsetBy: -1)
            guard startIndex < endIndex else { return "" }
            return String(line[startIndex..<endIndex])
        }
        return nil
    }

    /// 解析时间标签字符串为秒 (保持不变)
    private func parseTimeTag(timeString: String) -> TimeInterval? {
        let components = timeString.components(separatedBy: CharacterSet(charactersIn: ":."))
        guard components.count >= 2 else { return nil }
        let minutes: TimeInterval
        let seconds: TimeInterval
        let milliseconds: TimeInterval
        do {
            minutes = try TimeInterval(parseComponent(components[0])) * 60
            seconds = try TimeInterval(parseComponent(components[1]))
            if components.count >= 3 {
                let fractionStr = components[2]
                let fractionDigits = fractionStr.count
                let fractionValue = try parseComponent(fractionStr)
                if fractionDigits == 1 { milliseconds = TimeInterval(fractionValue) / 10.0 }
                else if fractionDigits == 2 { milliseconds = TimeInterval(fractionValue) / 100.0 }
                else if fractionDigits == 3 { milliseconds = TimeInterval(fractionValue) / 1000.0 }
                else { milliseconds = 0; flog.error("Unsupported time fraction format: \(fractionStr)") }
            } else { milliseconds = 0 }
            guard minutes >= 0, seconds >= 0, milliseconds >= 0 else { return nil }
            return minutes + seconds + milliseconds
        } catch {
            flog.error("Failed to parse time component in '\(timeString)': \(error)")
            return nil
        }
    }

    /// 辅助：解析数字组件 (保持不变)
    private func parseComponent(_ component: String) throws -> Double {
        guard let value = Double(component) else {
            throw NSError(domain: "LyricsParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid number format: \(component)"])
        }
        return value
    }

    /// 插入头部信息作为歌词行 (保持不变，但可能不再需要或需要调整)
    private func insertHeaderAsLyrics() {
        guard !lyrics.isEmpty, header.hasContent else { return }
        var headers: [(String, String?)] = []
        if let title = header.title { headers.append(("标题", title)) }
        // ... (添加其他头部信息) ...
        if headers.isEmpty { return }
        let firstLyricTime = lyrics[0].time
        let intervalPerHeader = firstLyricTime > 0 ? (firstLyricTime * 0.8 / TimeInterval(headers.count + 1)) : 0
        let startTimeOffset: TimeInterval = firstLyricTime > 0 ? intervalPerHeader * 0.5 : 0
        var headerLyrics: [LyricsItem] = headers.enumerated().map { index, element in
            let time = startTimeOffset + intervalPerHeader * TimeInterval(index)
            let text = "\(element.0): \(element.1 ?? "")"
            return LyricsItem(time: time, text: text) // 头部信息没有 wordInfos
        }
        if !headerLyrics.isEmpty {
            let finalTime = startTimeOffset + intervalPerHeader * TimeInterval(headers.count)
            headerLyrics.append(LyricsItem(time: finalTime, text: ""))
        }
        lyrics.insert(contentsOf: headerLyrics, at: 0)
        flog.debug("Inserted \(headerLyrics.count) header lines into lyrics.")
    }
}

// LyricsHeader 的 hasContent 辅助属性 (保持不变)
extension LyricsHeader {
    var hasContent: Bool { title != nil || author != nil || album != nil || by != nil || editor != nil || version != nil || offset != 0 }
}
