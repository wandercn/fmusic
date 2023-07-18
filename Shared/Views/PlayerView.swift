//
//  PlayerView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//
import AVFoundation
import SwiftUI
var soudPlayer: AVAudioPlayer?

enum PlayMode {
    case Loop
    case Order
    case Random
    case Single
}

struct PlayerView: View {
    let timer = Timer
        .publish(every: 0.1, on: .main, in: .common)
        .autoconnect()
    @Binding var libraryList: [Song]
    @Binding var currnetSong: Song

    @State var playMode: PlayMode = .Order
    @State var modeImage: String = "arrow.uturn.forward.circle"
    @State var volume: Float = 0.7
    @State var autoPlay = true
    @State var currtime: TimeInterval = 0.0 // 当前播放时长
    @State var percentage = 0.0 // 播放进度比率
    @State var isEditing = false // 是否手工拖动进度条
    @State var showPlayButton = true // 是否显示播放按钮图标，为false时，显示暂停按钮
    @State var progressMaxWidth = 300.0
    @State var lastDragValue = 0.0
    @State var progressWidth = 0.0
    @State var img = Image("album")
    @State var showImage = false
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            HStack(alignment: .center) {
                if showImage {
                    img
                        .resizable()
                        .frame(width: 64, height: 64)
                        .circleImage()
                        .imageOnHover()
                } else {
                    Image("album")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .circleImage()
                        .imageOnHover()
                }
                // 显示当前歌曲名和艺术家
                VStack(alignment: .leading) {
                    Text(currnetSong.artist)
                        .foregroundColor(.secondary)
                    Text(currnetSong.name)
                        .padding(.vertical, 5)
                        .foregroundColor(.black)
                }
                .frame(minWidth: 100)
                .onChange(of: currnetSong.filePath) { _ in
                    if let coverjpg = GetAlbumCoverImage(path: currnetSong.filePath) {
                        img = coverjpg
                    } else {
                        img = Image("album")
                    }
                    showImage = true
                    soudPlayer?.currentTime = 0
                    soudPlayer?.stop()
                    playAudio(path: currnetSong.filePath)
                    if let total = soudPlayer?.duration {
                        currnetSong.duration = total
                    }
                    showPlayButton = false
                    // 切换歌曲后，进度长度重置为0
                    lastDragValue = 0
                    progressWidth = 0

                    if $libraryList.count > 0 {
                        for index in 0..<$libraryList.count {
                            if libraryList[index].filePath == currnetSong.filePath {
                                libraryList[index].isPlaying = true
                            } else {
                                libraryList[index].isPlaying = false
                            }
                        }
                    }
                }

                Spacer()
                // 播放进度条
                HStack {
                    ProgressView(value: percentage, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(Color.pink)
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
                                //                                let progress = lastDragValue / progressMaxWidth
                                //
                                //                                percentage = progress <= 1.0 ? progress : 1
                                //                                print("progress2: \(progress)")
                                print("isEditing2: \(isEditing)")
                                isEditing = false
                                print("isEditing3: \(isEditing)")
                            }
                        )
                        .onReceive(timer) { _ in
                            if isEditing {
                                // 手工调整播放进度
                                soudPlayer?.currentTime = percentage * currnetSong.duration
                                flog.debug("progress3: \(percentage)")

                            } else {
                                if let currTime = soudPlayer?.currentTime {
                                    currtime = currTime
                                    percentage = currtime / currnetSong.duration
                                }
                            }
                            // 播放完成
                            if let player = soudPlayer {
                                let old = currnetSong
                                if !player.isPlaying, autoPlay, !showPlayButton {
                                    flog.debug("isplaying: \(player.isPlaying)")
                                    flog.debug("autoPlay: \(autoPlay)")
                                    currnetSong = nextSong(currSong: old, playList: libraryList, playMode: playMode)
                                    // 单曲循环模式特殊处理
                                    if playMode == .Single {
                                        soudPlayer?.currentTime = 0
                                        soudPlayer?.play()
                                        showPlayButton = false
                                    }
                                }
                            }
                        }
                    // 显示当前播放时长
                    Text(durationFormat(timeInterval: currtime)+" / "+durationFormat(timeInterval: currnetSong.duration))
                }.frame(width: progressMaxWidth)
                // 收藏按钮
                Button(action: {
                    currnetSong.isHeartChecked.toggle()
                    if $libraryList.count > 0 {
                        for index in 0..<$libraryList.count {
                            if libraryList[index].filePath == currnetSong.filePath {
                                libraryList[index].isHeartChecked = currnetSong.isHeartChecked
                            }
                        }
                    }
                    flog.debug("点击了收藏")
                }) {
                    Image(systemName: currnetSong.isHeartChecked ? "heart.circle.fill" : "heart.circle")
                        .font(.largeTitle)
                        .pinkBackgroundOnHover()
                }
                .buttonStyle(.borderless)

                Button(action: {
                    let old = playMode
                    flog.debug("old playMode: \(old)")
                    (playMode, modeImage) = nextPlayMode(mode: old)
                    flog.debug("new playMode: \(playMode)")
                }) { Image(systemName: modeImage)
                    .font(.largeTitle)
                }
                .buttonStyle(.borderless)
                .pinkBackgroundOnHover()
                // 媒体播放控制按钮
                HStack {
                    // 上一曲按钮
                    Button(action: {
                        let old = currnetSong
                        currnetSong = prevSong(currSong: old, playList: libraryList, playMode: playMode)
                    }) {
                        Image(systemName: "backward.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()
                    // 播放/暂停按钮
                    Button(action: {
                        if showPlayButton {
                            if currtime == 0 {
                                if currnetSong.filePath.isEmpty, !libraryList.isEmpty {
                                    currnetSong = libraryList.first!
                                }
                                playAudio(path: currnetSong.filePath)
                                if let total = soudPlayer?.duration {
                                    currnetSong.duration = total
                                }
                            } else {
                                // 当前播放时长大于0 表示暂停，恢复播放就行。
                                soudPlayer?.play()
                            }
                        } else {
                            soudPlayer?.pause()
                        }
                        // 切换显示按钮
                        showPlayButton.toggle()

                    }) {
                        Image(systemName: showPlayButton ? "play.circle" : "pause.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()

                    // 下一曲按钮
                    Button(action: {
                        let old = currnetSong
                        currnetSong = nextSong(currSong: old, playList: libraryList, playMode: playMode)
                    }) {
                        Image(systemName: "forward.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()
                }
                // 音量调整滚动条
                HStack {
                    Image(systemName: "speaker.fill")
                    Slider(
                        value: $volume,
                        in: 0...1.0,
                        onEditingChanged: { _ in
                            soudPlayer?.setVolume(volume, fadeDuration: 0)
                        }
                    )
                    .tint(Color.red)
                    Image(systemName: "speaker.wave.3.fill")
                }
                .frame(width: 150)

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

// 播放音频文件
func playAudio(path: String) {
    let url = URL(fileURLWithPath: path)
    do {
        soudPlayer?.stop()
        soudPlayer = try AVAudioPlayer(contentsOf: url)
        soudPlayer?.prepareToPlay()
        soudPlayer?.play()

    } catch {
        flog.error("读取音频文件失败:\(path) error: \(error)")
    }
}

// 切换播放模式，返回下一个模式和对应的图片名称
func nextPlayMode(mode: PlayMode) -> (playMode: PlayMode, image: String) {
    switch mode {
    case .Loop:
        return (.Order, "arrow.uturn.forward.circle")
    case .Order:
        return (.Random, "shuffle.circle")
    case .Random:
        return (.Single, "repeat.1.circle")
    case .Single:
        return (.Loop, "repeat.circle")
    }
}

// 返回下一曲的歌曲信息，根据不同的播放模式返回不同
func nextSong(currSong: Song, playList: [Song], playMode: PlayMode) -> Song {
    switch playMode {
    case .Loop:
        flog.debug("播放模式:\(PlayMode.Loop)")
        for index in 0..<playList.count {
            if currSong.filePath == playList[index].filePath {
                return playList[index+1 > playList.count ? 0 : index+1]
            }
        }
    case .Order:
        flog.debug("播放模式:\(PlayMode.Order)")
        for index in 0..<playList.count {
            if index+1 > playList.count {
                soudPlayer?.stop()
            }
            if currSong.filePath == playList[index].filePath {
                flog.debug("\(playList[index+1 >= playList.count ? index : index+1].name)")
                return playList[index+1 >= playList.count ? index : index+1]
            }
        }
    case .Random:
        flog.debug("播放模式:\(PlayMode.Random)")
        let nextId = Int.random(in: 0...(playList.count - 1))
        return playList[nextId]

    case .Single:
        flog.debug("播放模式:\(PlayMode.Single)")
        return currSong
    }

    return currSong
}

// 返回上一曲的歌曲信息，根据不同的播放模式返回不同
func prevSong(currSong: Song, playList: [Song], playMode: PlayMode) -> Song {
    switch playMode {
    case .Loop:
        flog.debug("播放模式:\(PlayMode.Loop)")
        for index in 0..<playList.count {
            if currSong.filePath == playList[index].filePath {
                return playList[index - 1 <= 0 ? 0 : index - 1]
            }
        }
    case .Order:
        flog.debug("播放模式:\(PlayMode.Order)")
        for index in 0..<playList.count {
            if currSong.filePath == playList[index].filePath {
                flog.debug("\(playList[index - 1 <= 0 ? 0 : index - 1].name)")
                return playList[index - 1 <= 0 ? 0 : index - 1]
            }
        }
    case .Random:
        flog.debug("播放模式:\(PlayMode.Random)")
        let nextId = Int.random(in: 0...(playList.count - 1))
        return playList[nextId]

    case .Single:
        flog.debug("播放模式:\(PlayMode.Single)")
        return currSong
    }
    return currSong
}

func durationFormat(timeInterval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.pad]
    return formatter.string(from: timeInterval)!
}
