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
                        LineView(line: line, curId: $player.curId)
                            .lineSpacing(20)
                    }

                    Spacer().frame(height: 200)
                }
                .onAppear {
                    proxy.scrollTo(0, anchor: .top)
                }

                .onChange(of: player.curLyricsIndex) { _ in
                    flog.debug("curLyricsIndex \(player.curLyricsIndex)")
                    proxy.scrollTo(player.curId, anchor: .center)
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

struct LineView: View {
    @State var line: LyricsItem
    @Binding var curId: UUID
    var body: some View {
        HStack {
            if line.id == curId {
                Text(line.text)
                    .font(.title3)
                    .foregroundColor(.white)
                    .bold()
                    .animation(.spring())
                    .id(curId)
            } else {
                Text(line.text)
                    .font(.title3)
                    .foregroundColor(Color("lyfgColor"))
                    .id(line.id)
            }
        }
        .frame(height: 30)
    }
}
