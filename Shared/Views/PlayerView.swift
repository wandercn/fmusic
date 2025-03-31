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
    // @ObservedObject 依赖 AudioPlayer
    @ObservedObject var player: AudioPlayer

    // 配置
    @State var progressMaxWidth: Double = 250.0

    // 与父视图的绑定 (如果需要)
    @Binding var lastDragValue: Double
    @Binding var progressWidth: Double // 当前视觉宽度

    // 内部状态
    @State var percentage: Double = 0.0 // 播放进度比例
    @State var isEditing: Bool = false // 是否正在拖动

    // 用于可靠更新文本的状态变量
    @State private var currentTimeText: String = "00:00"
    @State private var totalTimeText: String = "00:00"

    var body: some View {
        HStack(spacing: 8) { // 添加间距
            // 进度条
            ProgressView(value: percentage, total: 1.0)
                .progressViewStyle(.linear)
                .frame(maxWidth: progressMaxWidth) // 限制宽度
                // 拖动手势
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isEditing { isEditing = true; flog.debug("拖动开始.") }

                        let translation = value.translation
                        var currentWidth = translation.width + lastDragValue
                        currentWidth = max(0, min(currentWidth, progressMaxWidth))
                        progressWidth = currentWidth

                        let duration = player.Duration()
                        if duration > 0, duration.isFinite {
                            let currentPercentage = currentWidth / progressMaxWidth
                            percentage = max(0, min(currentPercentage, 1.0))
                            let estimatedTime = percentage * duration
                            currentTimeText = durationFormat(timeInterval: estimatedTime)
                        } else {
                            percentage = 0.0
                            currentTimeText = "00:00"
                        }
                    }
                    .onEnded { value in
                        flog.debug("拖动结束.")
                        let translation = value.translation
                        var finalWidth = translation.width + lastDragValue
                        finalWidth = max(0, min(finalWidth, progressMaxWidth))

                        let duration = player.Duration()
                        var clampedPercentage = 0.0
                        if duration > 0, duration.isFinite {
                            let finalPercentage = finalWidth / progressMaxWidth
                            clampedPercentage = max(0, min(finalPercentage, 1.0))
                        }

                        percentage = clampedPercentage
                        progressWidth = finalWidth
                        lastDragValue = finalWidth

                        flog.debug("拖动结束百分比: \(percentage)")

                        let targetTime = clampedPercentage * duration
                        if targetTime.isFinite {
                            player.SetCurrentTime(value: targetTime)
                            flog.debug("跳转到时间: \(targetTime)")
                            updateLyrics(currentTime: targetTime)
                            currentTimeText = durationFormat(timeInterval: targetTime)
                        } else {
                            flog.error("拖动结束: 计算出无效跳转时间 (\(targetTime))，时长为 (\(duration))")
                        }

                        // 稍微延迟后重置编辑状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if isEditing { // 确保仍然是编辑状态
                                isEditing = false
                                flog.debug("isEditing 设为 false (延迟后).")
                            }
                        }
                    }
                )
                // --- 接收时间更新 ---
                .onReceive(player.currentTimePublisher) { currentTime in
                    guard !isEditing else { return } // 非编辑状态才更新

                    let duration = player.Duration()
                    if duration > 0 && duration.isFinite && currentTime.isFinite {
                        let currentPercentage = min(max(0, currentTime / duration), 1.0)
                        percentage = currentPercentage
                        currentTimeText = durationFormat(timeInterval: currentTime)
                        updateLyrics(currentTime: currentTime)
                        // flog.debug("进度条更新 - %: \(percentage), Time: \(currentTimeText)")
                    } else if percentage != 0.0 || currentTimeText != "00:00" { // 如果时长无效，重置显示
                        percentage = 0.0
                        currentTimeText = "00:00"
                        // 可能也需要重置歌词？
                        // updateLyrics(currentTime: 0.0)
                    }
                }
                // --- 接收时长更新 ---
                .onReceive(player.$currentSongDuration.compactMap { $0 }) { durationValue in
                    flog.debug("进度条收到时长更新: \(durationValue)")
                    if durationValue > 0, durationValue.isFinite {
                        totalTimeText = durationFormat(timeInterval: durationValue)
                    } else {
                        totalTimeText = "00:00" // 处理无效时长
                        flog.error("收到无效时长更新: \(durationValue)")
                    }
                }

            // 显示时间文本
            Text("\(currentTimeText) / \(totalTimeText)")
                .font(.system(.title3, design: .default)) // macOS 11 兼容
                .frame(minWidth: 90, alignment: .center) // 给文本固定宽度
        }
        .frame(width: progressMaxWidth) // 根据需要调整总宽度
        .padding(.horizontal) // 左右内边距
        .onAppear {
            initializeProgressBarState() // 初始化状态
            flog.debug("进度条已出现 (onAppear)。")
        }
        .help("鼠标拖拽可调整播放进度")
    }

    // --- 初始化状态辅助函数 ---
    private func initializeProgressBarState() {
        flog.debug("初始化进度条状态...")
        let initialTime = player.CurrentTime()
        let duration = player.Duration() // 获取当前时长

        flog.debug("初始化 - 当前时间: \(initialTime), 时长: \(duration)")

        // 设置总时长文本
        if duration > 0, duration.isFinite {
            totalTimeText = durationFormat(timeInterval: duration)
        } else {
            totalTimeText = "00:00"
            flog.debug("初始化 - 初始时长无效。")
        }

        // 设置当前时间文本和百分比
        if duration > 0, duration.isFinite, initialTime.isFinite, initialTime >= 0 {
            percentage = max(0, min(initialTime / duration, 1.0))
            currentTimeText = durationFormat(timeInterval: initialTime)
        } else {
            percentage = 0.0
            currentTimeText = "00:00"
            flog.debug("初始化 - 初始时间或时长无效，无法计算百分比。")
        }

        // 初始化拖动相关状态
        progressWidth = percentage * progressMaxWidth
        lastDragValue = progressWidth

        // 更新初始歌词
        updateLyrics(currentTime: initialTime)

        flog.debug("初始化 - 状态: %=\(percentage), Cur=\(currentTimeText), Tot=\(totalTimeText), Width=\(progressWidth)")
    }

    // --- 歌词更新逻辑 (辅助函数) ---
    private func updateLyrics(currentTime: TimeInterval) {
        // 确保 player 和 parser 有效且有歌词数据
        let parser = player.lyricsParser
        guard !parser.lyrics.isEmpty
        else {
            if player.curLyricsIndex != -1 { // 仅当需要重置时更新
                player.curLyricsIndex = -1
                player.currentLyrics = ""
            }
            return
        }

        // 计算生效时间（考虑偏移）
        let effectiveTime = currentTime + player.offsetTime
        var newLyricsIndex = -1 // 初始化为未找到

        // 查找当前时间对应的歌词索引 (使用 lastIndex 效率较高)
        if let foundIndex = parser.lyrics.lastIndex(where: { $0.time <= effectiveTime }) {
            newLyricsIndex = foundIndex
        } else {
            newLyricsIndex = -1 // 时间在第一句歌词之前
        }

        // 仅当索引发生变化时才更新 @Published 属性，避免不必要的 UI 刷新
        if newLyricsIndex != player.curLyricsIndex {
            if newLyricsIndex == -1 {
                // 在第一句之前
                player.curLyricsIndex = -1
                player.currentLyrics = ""
                // flog.debug("歌词状态更新: 在第一句之前。")
            } else {
                // 检查索引是否在有效范围内
                if newLyricsIndex < parser.lyrics.count {
                    let newLyricItem = parser.lyrics[newLyricsIndex]
                    player.curLyricsIndex = newLyricsIndex
                    player.curId = newLyricItem.id
                    player.currentLyrics = newLyricItem.text
                    // flog.debug("歌词状态更新: 索引 \(newLyricsIndex), ID \(newLyricItem.id)")
                } else {
                    flog.error("歌词更新错误: 计算出的索引 \(newLyricsIndex) 超出范围 (\(parser.lyrics.count))。")
                    // 如果索引无效，重置状态
                    player.curLyricsIndex = -1
                    player.currentLyrics = ""
                }
            }
        }
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
