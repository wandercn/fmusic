//
//  LyricsView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/25.
//

import SwiftUI
struct LyricsView: View {
    @ObservedObject var player: AudioPlayer
    var body: some View {
        VStack {
            HStack {
                Text("\(player.lyricsParser.header.title ?? "")")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            .frame(height: 50)
            // 歌词滚动显示区域
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    ForEach(player.lyricsParser.lyrics, id: \.id) { line in
                        KaraokeLineView(
                            line: line,
                            // 传递卡拉OK状态
                            currentWordIndex: (line.id == player.curId) ? player.currentWordIndex : nil,
                            currentWordProgress: (line.id == player.curId) ? player.currentWordProgress : 0.0,
                            // 判断是否为当前行
                            isCurrentLine: line.id == player.curId
                        )
                        .id(line.id)
                    }

                    Spacer().frame(height: 200)
                }
                .onAppear {
                    proxy.scrollTo(0, anchor: .top)
                }

                .onChange(of: player.curId) { idToScroll in
                    // flog.debug("Scrolling to lyric ID: \(idToScroll)")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(idToScroll, anchor: .center) // 滚动到行
                    }
                }
            }
            .frame(minWidth: 300, maxWidth: .infinity)
        }
        .background(Color("lybgColor"))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // 歌词时间偏移调整
                HStack(spacing: 0) {
                    Image(systemName: "timer")
                    Slider(value: $player.offsetTime, in: -30 ... 30, step: 0.1)
                    Text(String(format: "%.1fs", player.offsetTime))
                }.frame(minWidth: 250, maxWidth: .infinity)
                    .help("调整歌词显示时间")
                    .padding(.horizontal, 10)
            }
        }
    }
}

struct KaraokeLineView: View {
    let line: LyricsItem
    let currentWordIndex: Int? // 当前高亮到哪个词的索引
    let currentWordProgress: Double // 当前高亮词的进度 (0.0 - 1.0)
    let isCurrentLine: Bool // 这是否是当前播放的整行歌词

    // 定义普通颜色和高亮颜色
    let normalColor: Color = .init("lyfgColor") // 未播放部分的颜色
    let highlightedColor: Color = .white // 已播放部分的颜色
    let currentLineScale: CGFloat = 1 // 当前行放大效果 (可选)
    let otherLineScale: CGFloat = 1

    var body: some View {
        // 如果没有逐字信息，显示普通文本
        if line.wordInfos.isEmpty {
            Text(line.text)
                .foregroundColor(isCurrentLine ? highlightedColor : normalColor) // 整行高亮
                .font(.title3) // 示例字体
                .scaleEffect(isCurrentLine ? currentLineScale : otherLineScale) // 放大当前行
                .animation(.easeInOut(duration: 0.3), value: isCurrentLine) // 添加动画
                .padding(.vertical, 5) // 增加行间距
        } else {
            // 有逐字信息，渲染卡拉OK效果
            HStack(spacing: 0) { // 使用 HStack 将每个字/词片段水平排列，无间距
                ForEach(Array(line.wordInfos.enumerated()), id: \.element.id) { index, wordInfo in
                    // 创建每个字/词的视图
                    renderWord(wordInfo: wordInfo, index: index)
                }
            }
            .font(.title3) // 应用统一字体
            .scaleEffect(isCurrentLine ? currentLineScale : otherLineScale) // 放大当前行
            .animation(.easeInOut(duration: 0.3), value: isCurrentLine) // 添加动画
            .padding(.vertical, 5) // 增加行间距
        }
    }

    // 渲染单个字/词的视图，带卡拉OK效果
    @ViewBuilder
    private func renderWord(wordInfo: WordInfo, index: Int) -> some View {
        // 计算这个字/词的高亮状态和进度
        let highlightProgress: Double = calculateHighlightProgress(for: index)

        // 使用 ZStack 和 Mask 实现颜色渐变效果
        ZStack(alignment: .leading) {
            // 底层：普通颜色文本
            Text(wordInfo.word)
                .foregroundColor(normalColor)

            // 上层：高亮颜色文本
            Text(wordInfo.word)
                .foregroundColor(highlightedColor)
                // 使用 mask 来根据进度裁剪高亮文本
                .mask(
                    GeometryReader { geo in
                        // 创建一个矩形，其宽度根据 highlightProgress 变化
                        Rectangle()
                            .frame(width: geo.size.width * highlightProgress)
                    }
                )
        }
        // 使用固定大小字体时，可以移除 .fixedSize()
        // .fixedSize(horizontal: true, vertical: false) // 防止文本换行影响布局
    }

    // 这个函数不是 @ViewBuilder，只是普通的计算逻辑
    private func calculateHighlightProgress(for index: Int) -> Double {
        // 如果不是当前播放的行，进度为 0
        guard isCurrentLine else { return 0.0 }

        // 如果当前行有高亮的词索引
        if let currentHighlightIndex = currentWordIndex {
            if index < currentHighlightIndex {
                // 这个词在高亮词之前，进度为 1 (完全高亮)
                return 1.0
            } else if index == currentHighlightIndex {
                // 这个词就是当前正在高亮的词，使用传入的进度
                return currentWordProgress
            } else {
                // 这个词在高亮词之后，进度为 0 (未高亮)
                return 0.0
            }
        } else {
            // 当前行还没有任何词开始高亮（例如在行的起始时间之前），进度为 0
            return 0.0
        }
    }
}
