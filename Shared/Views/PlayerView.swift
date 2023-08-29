//
//  PlayerView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//
import AVFoundation
import SwiftUI

struct PlayerView: View {
    @ObservedObject var player: AudioPlayer

    @State var showPlayButton = true // 是否显示播放按钮图标，为false时，显示暂停按钮
    @State var lastDragValue = 0.0
    @State var progressWidth = 0.0
    @State var playModeHelp = "顺序播放"
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            HStack(alignment: .center) {
                player.albumCover
                    .resizable()
                    .frame(width: 64, height: 64)
                    .circleImage()
                    .imageOnHover()
                // 显示当前歌曲名和艺术家
                VStack(alignment: .leading) {
                    Text(player.currentSong.artist)
                        .foregroundColor(.secondary)
                    Text(player.currentSong.name)
                        .padding(.vertical, 5)
                        .foregroundColor(.black)
                    Text(player.currentLyrics)
                        .foregroundColor(.black)
                        .animation(.spring())
                }
                .frame(minWidth: 100)
                .onChange(of: player.currentSong.filePath) { _ in
                    if let coverjpg = GetAlbumCoverImage(path: player.currentSong.filePath) {
                        player.albumCover = coverjpg
                    } else {
                        player.albumCover = Image("album")
                    }
                    player.SetCurrentTime(value: 0)
                    player.Stop()
                    player.PlayAudio(path: player.currentSong.filePath)
                    player.currentSong.duration = player.Duration()

                    showPlayButton = false
                    // 切换歌曲后，进度长度重置为0
                    lastDragValue = 0
                    progressWidth = 0

                    // 更新播放列表中当前正在播放的歌曲
                    player.UpdatePlaying()
                }

                Spacer()
                // 播放进度条
                ProgressBar(player: player, lastDragValue: $lastDragValue, progressWidth: $progressWidth)
                Spacer()
                // 收藏按钮
                HeartButton(player: player)
                    .help("点击收藏")
                // 播放模式切换按钮
                PlayModeButton(player: player, helpStr: $playModeHelp)
                    .help(playModeHelp)
                // 媒体播放控制按钮
                PlayControlBar(player: player, showPlayButton: $showPlayButton)
                Spacer()
                // 音量调整滚动条
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(
                        value: $player.volume,
                        in: 0 ... 1.0,
                        onEditingChanged: { _ in
                            player.SetVolume(value: player.volume)
                        }
                    )

//                    .tint(Color.red) // macOS 12.0

                    Image(systemName: "speaker.wave.3.fill")
                }
                .frame(width: 120)
                .help("调节音量大小")

            }.frame(height: 48)
                .padding()
                .background(RoundedRectangle(cornerSize: CGSize.zero)
                    .fill(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                )
                .foregroundColor(Color.secondary)
        }
    }
}

struct PlayModeButton: View {
    @ObservedObject var player: AudioPlayer
    @State private var modeImage: String = "list.bullet.circle"
    @Binding var helpStr: String
    var body: some View {
        Button(action: {
            let old = player.playMode
            flog.debug("old playMode: \(old)")
            (player.playMode, modeImage, helpStr) = nextPlayMode(mode: old)
            flog.debug("new playMode: \(player.playMode)")
        }) { Image(systemName: modeImage)
            .font(.largeTitle)
        }
        .buttonStyle(.borderless)
        .pinkBackgroundOnHover()
    }
}

struct HeartButton: View {
    @ObservedObject var player: AudioPlayer
    var body: some View {
        Button(action: {
            player.currentSong.isHeartChecked.toggle()
            player.UpdateHeartChecked()
            flog.debug("点击了收藏")
        }) {
            Image(systemName: player.currentSong.isHeartChecked ? "heart.circle.fill" : "heart.circle")
                .font(.largeTitle)
                .pinkBackgroundOnHover()
        }
        .buttonStyle(.borderless)
    }
}

struct ProgressBar: View {
    @ObservedObject var player: AudioPlayer
    let timer = Timer
        .publish(every: 0.1, on: .main, in: .common)
        .autoconnect()
    @State var progressMaxWidth = 250.0
    @Binding var lastDragValue: Double
    @Binding var progressWidth: Double
    @State var percentage = 0.0 // 播放进度比率
    @State var isEditing = false // 是否手工拖动进度条
    var body: some View {
        HStack {
            ProgressView(value: percentage, total: 1.0)
                .progressViewStyle(.linear)
//                .tint(Color.pink)
                // 拖拽播放进度
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isEditing = true
                        let translation = value.translation
                        progressWidth = translation.width+lastDragValue
                        progressWidth = progressWidth > progressMaxWidth ? progressMaxWidth : progressWidth
                        progressWidth = progressWidth >= 0 ? progressWidth : 0
                        let progress = progressWidth / progressMaxWidth
                        print("progress1: \(progress)")
                        percentage = progress <= 1.0 ? progress : 1
                        print("isEditing1: \(isEditing)")
                    }
                    .onEnded { _ in
                        progressWidth = progressWidth > progressMaxWidth ? progressMaxWidth : progressWidth
                        progressWidth = progressWidth >= 0 ? progressWidth : 0
                        lastDragValue = progressWidth
                        print("isEditing2: \(isEditing)")
                        isEditing = false
                        print("isEditing3: \(isEditing)")
                    }
                )
                .onReceive(timer) { _ in
                    if isEditing {
                        // 手工调整播放进度
                        player.SetCurrentTime(value: percentage * player.currentSong.duration)
                        flog.debug("progress3: \(percentage)")

                    } else {
                        percentage = player.CurrentTime() / player.Duration()
                    }
                    // 更新当前应该显示哪一行歌词和对应的UUID
                    let curTime = player.CurrentTime()
                    let index = player.lyricsParser.lyrics.firstIndex { item in
                        curTime+player.offsetTime < item.time
                    } ?? 0
                    player.curLyricsIndex = index
                    player.curId = player.lyricsParser.lyrics[index].id
                    player.currentLyrics = player.lyricsParser.lyrics[index].text
                }
            // 显示当前播放时长
            Text(durationFormat(timeInterval: player.CurrentTime())+" / "+durationFormat(timeInterval: player.currentSong.duration))
        }.frame(width: progressMaxWidth)
            .help("鼠标拖拽进度")
    }
}

struct PlayControlBar: View {
    @ObservedObject var player: AudioPlayer
    @Binding var showPlayButton: Bool // 是否显示播放按钮图标，为false时，显示暂停按钮
    var body: some View {
        HStack {
            // 上一曲按钮
            Button(action: {
                player.PlayPrev()
            }) {
                Image(systemName: "backward.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .pinkBackgroundOnHover()
            .help("上一曲")

            // 播放/暂停按钮
            Button(action: {
                if showPlayButton {
                    player.Play()
                } else {
                    player.Pause()
                }
                // 切换显示按钮
                showPlayButton.toggle()

            }) {
                Image(systemName: showPlayButton ? "play.circle" : "pause.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .pinkBackgroundOnHover()
            .help(showPlayButton ? "播放" : "暂停")

            // 下一曲按钮
            Button(action: {
                player.PlayNext()
            }) {
                Image(systemName: "forward.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            .pinkBackgroundOnHover()
            .help("下一曲")
        }
    }
}

// 切换播放模式，返回下一个模式和对应的图片名称
func nextPlayMode(mode: PlayMode) -> (playMode: PlayMode, image: String, helpStr: String) {
    switch mode {
    case .Loop:
        return (.Order, "list.bullet.circle", "顺序播放")
    case .Order:
        return (.Random, "shuffle.circle", "随机播放")
    case .Random:
        return (.Single, "repeat.1.circle", "单曲循环")
    case .Single:
        return (.Loop, "repeat.circle", "列表循环")
    }
}

func durationFormat(timeInterval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.pad]
    return formatter.string(from: timeInterval)!
}
