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
        ZStack {
            VStack {
                HStack {
                    Text("时间偏移:")
                        .foregroundColor(Color.white)
                    Slider(value: $player.offsetTime, in: -30 ... 30, step: 0.5)
                    Text("\(player.offsetTime)")
                        .foregroundColor(.white)
                }.background(Color.orange)

                Spacer()
            }
            .zIndex(10)
            ScrollView {
                ForEach(player.lyricsParser.lyrics, id: \.self) { line in
                    LineView(line: line, curId: $player.curId)
                        .lineSpacing(20)
                }

                .offset(x: 0, y: -((player.CurrentTime() / player.Duration() * 800.0) / 10).rounded() * 10)
            }
        }

        .background(Color.gray)
        .frame(minWidth: 300, maxWidth: .infinity)
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
                    .foregroundColor(Color.white)
                    .background(Rectangle().fill(Color.yellow))
                    .animation(.linear)
            } else {
                Text(line.text)
                    .frame(height: 15)
                    .font(.title3)
                    .foregroundColor(Color.white)
            }
        }
    }
}
