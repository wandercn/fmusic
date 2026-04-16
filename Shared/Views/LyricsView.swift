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
            titleHeader
            lyricContent
        }
        .background(Color("lybgColor"))
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                offsetSlider
            }
        }
    }

    private var titleHeader: some View {
        HStack {
            Text("\(player.lyricsParser.header.title ?? "")")
                .font(.headline)
                .foregroundColor(.yellow)
        }
        .frame(height: 50)
    }

    private var lyricContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(player.lyricsParser.lyrics, id: \.id) { line in
                        KaraokeLineView(
                            line: line,
                            currentWordIndex: (line.id == player.curId) ? player.currentWordIndex : nil,
                            currentWordProgress: (line.id == player.curId) ? player.currentWordProgress : 0.0,
                            isCurrentLine: line.id == player.curId
                        )
                        .id(line.id)
                    }
                    Spacer().frame(height: 200)
                }
            }
            .onChange(of: player.curId) { idToScroll in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(idToScroll, anchor: .center)
                }
            }
        }
        .frame(minWidth: 300, maxWidth: .infinity)
    }

    private var offsetSlider: some View {
        HStack(spacing: 0) {
            Image(systemName: "timer")
            Slider(value: $player.offsetTime, in: -30 ... 30, step: 0.1)
            Text(String(format: "%.1fs", player.offsetTime))
        }
        .frame(minWidth: 250, maxWidth: .infinity)
        .help("调整歌词显示时间")
        .padding(.horizontal, 10)
    }
}

struct KaraokeLineView: View {
    let line: LyricsItem
    let currentWordIndex: Int?
    let currentWordProgress: Double
    let isCurrentLine: Bool

    let normalColor: Color = Color("lyfgColor")
    let highlightedColor: Color = .white

    var body: some View {
        if line.wordInfos.isEmpty {
            Text(line.text)
                .foregroundColor(isCurrentLine ? highlightedColor : normalColor)
                .font(.title3)
                .animation(.easeInOut(duration: 0.3), value: isCurrentLine)
                .padding(.vertical, 5)
        } else {
            HStack(spacing: 0) {
                ForEach(Array(line.wordInfos.enumerated()), id: \.element.id) { index, wordInfo in
                    renderWord(wordInfo: wordInfo, index: index)
                }
            }
            .font(.title3)
            .animation(.easeInOut(duration: 0.3), value: isCurrentLine)
            .padding(.vertical, 5)
        }
    }

    @ViewBuilder
    private func renderWord(wordInfo: WordInfo, index: Int) -> some View {
        let highlightProgress: Double = calculateHighlightProgress(for: index)
        ZStack(alignment: .leading) {
            Text(wordInfo.word).foregroundColor(normalColor)
            Text(wordInfo.word).foregroundColor(highlightedColor)
                .mask(
                    GeometryReader { geo in
                        Rectangle().frame(width: geo.size.width * highlightProgress)
                    }
                )
        }
    }

    private func calculateHighlightProgress(for index: Int) -> Double {
        guard isCurrentLine, let currentHighlightIndex = currentWordIndex else { return 0.0 }
        if index < currentHighlightIndex { return 1.0 }
        if index == currentHighlightIndex { return currentWordProgress }
        return 0.0
    }
}
