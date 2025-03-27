//
//  AppDelegate.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/19.
//

import AVFoundation
import Combine
import LyricsService // Assuming this import is needed for searchLyrics
import SwiftUI

enum PlayMode {
    case Loop // 列表循环
    case Order // 顺序播放（播完停止或根据 nextSong 逻辑）
    case Random // 随机播放
    case Single // 单曲循环
}

// 时间格式化
func durationFormat(timeInterval: TimeInterval) -> String {
    let time = max(0, timeInterval)
    if !time.isFinite { return "00:00" } // 非有限值返回 "00:00"
    let interval = Int(time)
    let seconds = interval % 60 // 秒
    let minutes = (interval / 60) % 60 // 分
    return String(format: "%02d:%02d", minutes, seconds) // 格式化时间
}

// 检查文件是否存在
func fileExists(atPath path: String) -> Bool {
    FileManager.default.fileExists(atPath: path) // 文件存在性检查
}

// 检查并创建目录
func checkAndCreateDir(dir: String) {
    if FileManager.default.fileExists(atPath: dir) {
        flog.debug("\(dir)目录已存在") // 目录存在
    } else {
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            flog.debug("\(dir)目录创建成功") // 目录创建成功
        } catch {
            flog.error("无法创建目录,错误：\(error)") // 目录创建失败
        }
    }
}

// 下一首
private func nextSong(currentSong: Song, playList: [Song], playMode: PlayMode) -> Song {
    // 1. 处理播放列表为空的情况
    guard !playList.isEmpty else {
        flog.debug("nextSong: 播放列表为空，返回当前歌曲。")
        return currentSong
    }

    // 2. 查找当前歌曲在列表中的索引 (使用 ID 更可靠)
    guard let currentIndex = playList.firstIndex(where: { $0.id == currentSong.id }) else {
        // 如果当前歌曲不在列表中（理论上不应发生，除非列表被外部修改），返回列表第一首
        flog.error("nextSong: 未在播放列表中找到当前歌曲 ID (\(currentSong.id))，返回列表第一首。")
        return playList.first ?? currentSong // 如果列表为空则返回当前（虽然前面已检查）
    }

    // 3. 根据播放模式计算下一首歌
    switch playMode {
    case .Loop:
        // 列表循环：索引 + 1，如果超出末尾则回到开头 (使用取模运算)
        let nextIndex = (currentIndex + 1) % playList.count
        flog.debug("下一首 (循环): 索引 \(nextIndex)")
        return playList[nextIndex]

    case .Order:
        // 顺序播放：索引 + 1，但不回绕。如果到达末尾，返回当前歌曲本身，
        // 让调用者 (PlayNext) 知道已到达末尾并停止播放。
        let nextIndex = currentIndex + 1
        if nextIndex < playList.count { // 如果下一首索引在范围内
            flog.debug("下一首 (顺序): 索引 \(nextIndex)")
            return playList[nextIndex]
        } else { // 到达列表末尾
            flog.debug("下一首 (顺序): 到达列表末尾。")
            return currentSong // 返回当前歌曲，表示结束
        }

    case .Random:
        // 随机播放：
        if playList.count <= 1 { return currentSong } // 如果只有一首歌，返回当前
        // 生成一个随机索引，并简单尝试避免连续播放同一首歌
        var nextIndex = Int.random(in: 0..<playList.count)
        while nextIndex == currentIndex {
            nextIndex = Int.random(in: 0..<playList.count)
        }
        flog.debug("下一首 (随机): 索引 \(nextIndex)")
        return playList[nextIndex]

    case .Single:
        // 单曲循环：始终返回当前歌曲
        flog.debug("下一首 (单曲): 返回当前歌曲。")
        return currentSong
    }
}

// 上一首
private func prevSong(currentSong: Song, playList: [Song], playMode: PlayMode) -> Song {
    // 1. 处理播放列表为空的情况
    guard !playList.isEmpty else {
        flog.debug("prevSong: 播放列表为空，返回当前歌曲。")
        return currentSong
    }

    // 2. 查找当前歌曲在列表中的索引 (使用 ID)
    guard let currentIndex = playList.firstIndex(where: { $0.id == currentSong.id }) else {
        // 如果当前歌曲不在列表中，返回列表最后一首
        flog.error("prevSong: 未在播放列表中找到当前歌曲 ID (\(currentSong.id))，返回列表最后一首。")
        return playList.last ?? currentSong
    }

    // 3. 根据播放模式计算上一首歌
    switch playMode {
    case .Loop:
        // 列表循环：索引 - 1，如果小于 0 则回到末尾 (使用取模运算处理负数)
        let prevIndex = (currentIndex - 1 + playList.count) % playList.count
        flog.debug("上一首 (循环): 索引 \(prevIndex)")
        return playList[prevIndex]

    case .Order:
        // 顺序播放：索引 - 1，但不回绕。如果到达开头，返回当前歌曲本身。
        let prevIndex = currentIndex - 1
        if prevIndex >= 0 { // 如果上一首索引在范围内
            flog.debug("上一首 (顺序): 索引 \(prevIndex)")
            return playList[prevIndex]
        } else { // 到达列表开头
            flog.debug("上一首 (顺序): 到达列表开头。")
            // 可以选择返回第一首歌 playList[0] 或者当前歌曲 currentSong
            // 返回当前歌曲通常表示无法再向前
            return currentSong
        }

    case .Random:
        // 随机播放：逻辑同 nextSong，随机选一个不同的
        if playList.count <= 1 { return currentSong }
        var prevIndex = Int.random(in: 0..<playList.count)
        while prevIndex == currentIndex {
            prevIndex = Int.random(in: 0..<playList.count)
        }
        flog.debug("上一首 (随机): 索引 \(prevIndex)")
        return playList[prevIndex]

    case .Single:
        // 单曲循环：始终返回当前歌曲
        flog.debug("上一首 (单曲): 返回当前歌曲。")
        return currentSong
    }
}

// 歌词搜索函数
func searchLyrics(song: String, artist: String, timeout: Double, completion: @escaping ([Lyrics]?) -> Void) -> AnyCancellable? {
    flog.debug("正在为 \(song) - \(artist) 发起歌词搜索LyricsSearchRequest")
    let searchReq = LyricsSearchRequest(searchTerm: .info(title: song, artist: artist), duration: timeout)
    let provider = LyricsProviders.Group(service: [.kugou, .syair, .gecimi, .netease, .qq])
    var lyricsList: [Lyrics] = []
    let limitedTimePublisher = provider.lyricsPublisher(request: searchReq)
        .timeout(.seconds(timeout), scheduler: DispatchQueue.main)

    let cancellable = limitedTimePublisher.sink(
        receiveCompletion: { result in
            switch result {
            case .finished:
                flog.debug("歌词搜索正常完成。数量: \(lyricsList.count)")
                completion(lyricsList.isEmpty ? nil : lyricsList) // 如果为空返回 nil 以保持一致性？
            case .failure(let error):
                flog.error("歌词搜索失败或超时: \(error)")
                completion(nil)
            }
        },
        receiveValue: { lyrics in
            flog.debug("接收到歌词片段。")
            lyricsList.append(lyrics)
        }
    )
    return cancellable
}

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // --- 播放器实例 ---
    // @Published private var soudPlayer: AVAudioPlayer? // 直接发布 AVAudioPlayer 可能会有问题，设为 private
    private var soudPlayer: AVAudioPlayer?

    // --- 播放状态与信息 ---
    @Published var playList: [Song] = .init() // 播放列表
    @Published var isPlaying: Bool = false // 是否正在播放
    @Published var isfinished: Bool = false // 考虑是否需要，委托方法会处理播放完成
    @Published var currentSong = Song() // 当前播放的歌曲
    @Published var playMode: PlayMode = .Order // 播放模式
    @Published var volume: Float = 0.7 { // 音量
        didSet { // 当音量变化时更新播放器音量
            soudPlayer?.volume = volume
        }
    }

    @Published var albumCover = Image("album") // 确保 "album" 图片存在于 Assets 中

    // --- 时长处理 ---
    @Published var currentSongDuration: TimeInterval? = nil // 当前歌曲时长

    // --- 歌词 ---
    @Published var lyricsParser = LyricsParser() // 歌词解析器
    @Published var currentLyrics = "" // 当前高亮的歌词文本
    @Published var offsetTime: Double = 0 // 歌词时间偏移
    @Published var curId = UUID() // 当前高亮歌词行的 ID
    @Published var curLyricsIndex = -1 // 当前高亮歌词行的索引（-1 表示无）
    @Published var lyricsDir = NSHomeDirectory() + "/Music/Lyrics" // 简化路径
    @Published var currentWordIndex: Int? = nil // 当前高亮歌词行中，高亮到哪个字的索引
    @Published var currentWordProgress: Double = 0.0 // 当前高亮字已进行的进度 (0.0 到 1.0)

    // --- Combine ---
    private var updateTimer: Timer? // 定时器
    private let currentTimeSubject = PassthroughSubject<TimeInterval, Never>() // 当前时间发布者
    private var cancellables = Set<AnyCancellable>() // 用于管理订阅的集合

    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject
            .receive(on: DispatchQueue.main) // 确保订阅者在主线程接收
            .eraseToAnyPublisher()
    }

    // --- 初始化 ---
    override init() {
        super.init()
    }

    init(path: String) {
        super.init()
        playList = LoadFiles(dir: path) // 从指定路径加载播放列表
        if let firstSong = playList.first {
            currentSong = firstSong // 将第一首歌曲设为当前播放歌曲
        }
        flog.debug("AudioPlayer 已初始化，路径: \(path)")
    }

    deinit {
        flog.debug("AudioPlayer 析构。")
        stopAndCleanup() // 在析构时确保清理
    }

    // 计算卡拉OK进度的方法 ---
    private func updateKaraokeProgress(currentTime: TimeInterval) {
        // 检查当前是否有高亮的歌词行 (curLyricsIndex 有效)
        let currentLineIndex = curLyricsIndex
        guard
            currentLineIndex >= 0, // 确保索引有效
            currentLineIndex < lyricsParser.lyrics.count // 确保在范围内
        else {
            // 如果没有当前行，重置卡拉OK状态
            if currentWordIndex != nil || currentWordProgress != 0.0 {
                currentWordIndex = nil
                currentWordProgress = 0.0
            }
            return
        }

        let currentLine = lyricsParser.lyrics[currentLineIndex]
        let wordInfos = currentLine.wordInfos // 获取当前行的逐字信息

        // 如果当前行没有逐字信息，也重置卡拉OK状态
        guard !wordInfos.isEmpty else {
            if currentWordIndex != nil || currentWordProgress != 0.0 {
                currentWordIndex = nil
                currentWordProgress = 0.0
            }
            return
        }

        // 计算相对于当前行开始的时间
        let timeWithinLine = currentTime - currentLine.time + offsetTime // 加上歌词偏移

        // 查找当前时间应该高亮到哪个字/词
        var newWordIndex: Int? = nil
        var newWordProgress = 0.0

        // 从后往前找第一个 startTime <= timeWithinLine 的字
        if let foundIndex = wordInfos.lastIndex(where: { $0.startTime <= timeWithinLine }) {
            newWordIndex = foundIndex
            let currentWordInfo = wordInfos[foundIndex]
            // 计算该字已经进行的进度
            if currentWordInfo.duration > 0 { // 防止除以零
                let timeInWord = timeWithinLine - currentWordInfo.startTime
                newWordProgress = min(max(0.0, timeInWord / currentWordInfo.duration), 1.0) // 限制在 0.0 到 1.0
            } else {
                // 如果持续时间为 0，则认为已完成
                newWordProgress = timeWithinLine >= currentWordInfo.startTime ? 1.0 : 0.0
            }
        } else {
            // 时间在第一个字开始之前
            newWordIndex = nil
            newWordProgress = 0.0
        }

        // 只有在状态变化时才更新 @Published 属性
        if currentWordIndex != newWordIndex || currentWordProgress != newWordProgress {
            // flog.debug("Karaoke Update: WordIndex=\(String(describing: newWordIndex)), Progress=\(newWordProgress)") // 详细日志
            currentWordIndex = newWordIndex
            currentWordProgress = newWordProgress
        }
    }

    func PlayFirst() {
        if currentSong.filePath.isEmpty, let firstSong = playList.first {
            currentSong = firstSong
        }
        guard !currentSong.filePath.isEmpty else {
            flog.error("PlayFirst failed: No song file path available.")
            return
        }
        PlayAudio(path: currentSong.filePath)
        // Duration is now handled reactively via currentSongDuration
    }

    func PlayNext() {
        if playList.isEmpty { return }
        let oldSong = currentSong
        currentSong = nextSong(currentSong: oldSong, playList: playList, playMode: playMode)

        if playMode == .Single {
            // For single loop, just seek to beginning and play if already playing
            if isPlaying {
                seek(to: 0)
                // No need to call play() again if already playing
                // Ensure timer keeps running / restart if stopped?
                if updateTimer == nil { startUpdateTimer() } // Restart timer if somehow stopped
            } else {
                // If paused in single mode, just seek and play
                seek(to: 0)
                Play()
            }
        } else if oldSong.id != currentSong.id || !isPlaying { // Play only if song changed or wasn't playing
            PlayAudio(path: currentSong.filePath)
        } else {
            // If song is the same and was playing (e.g., end of list in Order mode without loop)
            // Decide what to do - maybe stop? Currently nextSong logic handles this.
        }
    }

    func PlayPrev() {
        if playList.isEmpty { return }
        let oldSong = currentSong
        currentSong = prevSong(currentSong: oldSong, playList: playList, playMode: playMode)

        if playMode == .Single {
            if isPlaying { seek(to: 0); if updateTimer == nil { startUpdateTimer() } }
            else { seek(to: 0); Play() }
        } else if oldSong.id != currentSong.id || !isPlaying {
            PlayAudio(path: currentSong.filePath)
        }
    }

    func Play() {
        guard let player = soudPlayer else {
            PlayFirst() // If no player exists, try to play the first song
            return
        }
        if !isPlaying { // Only play if not already playing
            if player.prepareToPlay() {
                if player.play() {
                    isPlaying = true
                    startUpdateTimer()
                    flog.debug("Playback resumed/started.")
                } else {
                    flog.error("AVAudioPlayer failed to play.")
                }
            } else {
                flog.error("AVAudioPlayer failed to prepareToPlay.")
            }
        }
    }

    func Pause() {
        guard let player = soudPlayer, isPlaying else { return }
        player.pause()
        isPlaying = false
        stopUpdateTimer()
        flog.debug("Playback paused.")
    }

    func Stop() { // Different from pause - stops entirely
        soudPlayer?.stop()
        isPlaying = false
        stopUpdateTimer()
        seek(to: 0) // Reset time to beginning after stop
        flog.debug("Playback stopped.")
    }

    // MARK: - Time & Volume & Seeking

    func SetCurrentTime(value: TimeInterval) {
        seek(to: value)
    }

    func CurrentTime() -> TimeInterval {
        soudPlayer?.currentTime ?? 0.0
    }

    func Duration() -> TimeInterval {
        // 使用已发布的 duration 属性
        currentSongDuration ?? 1.0 // 默认返回 1.0，避免除以零错误
    }

    func SetVolume(value: Float) {
        // 使用带有 didSet 的已发布 volume 属性
        volume = min(max(value, 0.0), 1.0) // 将音量限制在 0 到 1 之间
    }

    // 内部跳转函数
    private func seek(to time: TimeInterval) {
        guard let player = soudPlayer else { return }
        let duration = player.duration // 使用播放器的时长来限制跳转时间
        let validTime = max(0, min(time, duration)) // 确保跳转时间在有效范围内
        player.currentTime = validTime
        flog.debug("跳转到时间: \(validTime)")
        // 跳转后立即发送时间更新
        if !isPlaying { // 如果暂停，手动发送更新，因为定时器未运行
            currentTimeSubject.send(validTime)
        }
        // 跳转后立即更新卡拉OK状态
        updateKaraokeProgress(currentTime: validTime)
        // 如果正在播放，定时器会稍后发送更新
    }

    // 加载并播放指定的音频文件
    func PlayAudio(path: String) {
        // 1. 验证路径
        guard !path.isEmpty, fileExists(atPath: path) else {
            flog.error("播放音频失败：路径为空或文件不存在于 \(path)")
            // 可选：播放下一首或停止？
            return
        }

        let searchTimeOut: Double = 2 // 歌词搜索超时时间
        let url = URL(fileURLWithPath: path) // 创建文件 URL

        // 2. 停止并清理之前的播放器和定时器
        stopAndCleanup()

        // 3. 重置歌词等状态以准备播放新歌曲
        reset()

        // 4. 初始化并准备 AVAudioPlayer
        do {
            soudPlayer = try AVAudioPlayer(contentsOf: url)
            soudPlayer?.delegate = self // 设置代理
            soudPlayer?.volume = volume // 应用当前的音量设置

            // 尝试准备播放并获取时长
            if soudPlayer?.prepareToPlay() == true {
                let playerDuration = soudPlayer?.duration ?? 0.0
                if playerDuration > 0 {
                    currentSongDuration = playerDuration // 更新发布的总时长
                    flog.debug("AVAudioPlayer 已准备好。时长 = \(playerDuration)")
                } else {
                    // 如果播放器准备好了但时长为0（可能发生在某些格式或流），尝试使用歌曲预存的时长
                    currentSongDuration = currentSong.duration > 0 ? currentSong.duration : nil
                    flog.debug("AVAudioPlayer 已准备好，但时长为 0。使用歌曲预存时长: \(String(describing: currentSongDuration))")
                }
            } else {
                // 准备播放失败
                flog.error("AVAudioPlayer 初始化后准备播放失败。")
                currentSongDuration = currentSong.duration > 0 ? currentSong.duration : nil // 仍然尝试使用预存时长
            }

            // 5. 尝试开始播放
            if soudPlayer?.play() == true {
                isPlaying = true // 更新播放状态
                startUpdateTimer() // 启动定时器
                flog.debug("AVAudioPlayer 正在播放: \(path)")
                UpdatePlaying() // 更新播放列表中的高亮状态
            } else {
                flog.error("AVAudioPlayer 在准备后启动播放失败。")
                isPlaying = false
                stopUpdateTimer() // 确保定时器停止
            }

        } catch {
            // AVAudioPlayer 初始化失败
            flog.error("初始化或播放 AVAudioPlayer 失败，路径 \(path): \(error)")
            soudPlayer = nil
            isPlaying = false
            stopUpdateTimer()
            currentSongDuration = nil // 重置时长
            return // 如果播放器加载失败则退出
        }

        // --- 6. 处理歌词 ---
        checkAndCreateDir(dir: lyricsDir) // 确保歌词目录存在
        let lyricsFileName = "\(lyricsDir)/\(currentSong.name) - \(currentSong.artist).lrcx" // 构造歌词文件名

        if fileExists(atPath: lyricsFileName) {
            // 如果本地文件存在，直接加载
            loadLyricsFromFile(path: lyricsFileName)
        } else {
            // 如果本地文件不存在，尝试下载
            flog.debug("歌词文件未找到，尝试下载: \(lyricsFileName)")

            // 取消之前的歌词搜索任务
            cancellables.removeAll() // 示例：简单地清空所有之前的订阅（假设只有一个搜索任务需要管理）
            // 备选方案：如果更容易，可以单独保留 lyricsSearchCancellable
            // lyricsSearchCancellable?.cancel() // 取消上一个

            // 调用外部的 searchLyrics 函数
            searchLyrics(song: currentSong.name, artist: currentSong.artist, timeout: searchTimeOut) { [weak self] docs in
                guard let self = self else { return } // 安全解包 weak self

                // **检查当前歌曲是否已改变**
                // 因为这是异步回调，用户可能已经切歌了
                let currentSongFileNameCheck = "\(self.lyricsDir)/\(self.currentSong.name) - \(self.currentSong.artist).lrcx"
                guard lyricsFileName == currentSongFileNameCheck else {
                    flog.debug("歌词数据返回，但歌曲已切换。丢弃。")
                    return // 如果歌曲不匹配，则不处理下载的歌词
                }

                // 检查搜索结果
                guard let firstDoc = docs?.first else {
                    flog.error("未找到歌词或返回的数组为空: \(self.currentSong.name)")
                    // 可以考虑在这里设置 lyricsParser 为空或其他处理
                    DispatchQueue.main.async { self.lyricsParser = LyricsParser() }
                    return
                }

                // 获取歌词数据 (假设 Lyrics 结构体有一个 description 属性包含 LRC 字符串)
                let myData = firstDoc.description

                // 将下载的歌词数据写入文件
                do {
                    // 使用 String 的 write 方法写入，原子操作保证文件完整性
                    try myData.write(to: URL(fileURLWithPath: lyricsFileName), atomically: true, encoding: .utf8)
                    flog.debug("歌词数据已成功写入文件: \(lyricsFileName)")
                    // 写入成功后，从该文件加载歌词
                    self.loadLyricsFromFile(path: lyricsFileName)
                } catch {
                    flog.error("将歌词写入文件失败 \(lyricsFileName): \(error)")
                    // 写入失败，重置歌词解析器
                    DispatchQueue.main.async { self.lyricsParser = LyricsParser() }
                }

            }? // searchLyrics 返回的是 Optional<AnyCancellable>
                .store(in: &cancellables) // 将订阅存储在 cancellables 集合中进行管理
        }
    }

    // 辅助方法：从文件加载歌词
    private func loadLyricsFromFile(path: String) {
        do {
            let lyricsString = try ReadFile(named: path) // 读取文件内容
            // 解析歌词（确保在主线程更新 @Published 属性）
            // 如果解析耗时，也可以考虑先在后台线程解析
            DispatchQueue.main.async {
                self.lyricsParser = LyricsParser(lyrics: lyricsString)
                flog.debug("歌词加载成功: \(path)")
                // 加载后立即更新一次卡拉OK状态，以防音频已开始播放
                self.updateKaraokeProgress(currentTime: self.CurrentTime())
            }
        } catch {
            flog.error("读取歌词文件失败 \(path): \(error)")
            // 加载失败时重置解析器
            DispatchQueue.main.async {
                self.lyricsParser = LyricsParser() // 重置为空解析器
            }
        }
    }

    // 重置歌词相关的状态
    private func reset() {
        offsetTime = 0 // 重置偏移
        currentLyrics = "" // 重置当前行文本
        curLyricsIndex = -1 // 重置当前行索引 (使用 -1 表示没有选中任何行)
        currentWordIndex = nil // 重置当前字索引
        currentWordProgress = 0.0 // 重置当前字进度
        // 在主线程重置解析器
        DispatchQueue.main.async {
            self.lyricsParser = LyricsParser() // 创建一个新的空解析器实例
        }
        flog.debug("歌词状态已重置。")
    }

    // MARK: - 定时器管理

    // 启动定时器以更新播放时间
    private func startUpdateTimer() {
        guard updateTimer == nil else { return } // 防止重复启动
        stopUpdateTimer() // 先确保停止旧的定时器

        // 创建定时器，每 0.1 秒触发一次 timerFired 方法
        updateTimer = Timer.scheduledTimer(timeInterval: 0.1, // 更新频率 (0.1秒 = 10Hz) - 卡拉OK可能需要更高频率，如 0.05s
                                           target: self,
                                           selector: #selector(timerFired), // 要调用的方法
                                           userInfo: nil,
                                           repeats: true) // 重复执行

        // 将定时器添加到 RunLoop 的 .common 模式，确保在滚动等 UI 操作时也能更新
        RunLoop.current.add(updateTimer!, forMode: .common)
        flog.debug("更新定时器已启动。")
    }

    // 停止定时器
    private func stopUpdateTimer() {
        if updateTimer != nil {
            updateTimer?.invalidate() // 使定时器失效
            updateTimer = nil // 释放定时器对象
            flog.debug("更新定时器已停止。")
        }
    }

    // 定时器触发时调用的方法
    @objc private func timerFired() {
        guard let player = soudPlayer, isPlaying else {
            // 如果播放器不存在或未在播放，则停止定时器
            stopUpdateTimer()
            return
        }
        let currentTime = player.currentTime // 获取播放器当前时间
        // flog.debug("AudioPlayer timerFired: 发送 currentTime = \(currentTime)") // 可选：详细日志
        currentTimeSubject.send(currentTime) // 通过 Subject 发布当前时间

        // 2.--- 计算卡拉OK进度 ---
        updateKaraokeProgress(currentTime: currentTime)
    }

    // MARK: - 播放列表管理 (来自用户代码的基本存根)

    // 更新播放列表中歌曲的播放状态标志
    func UpdatePlaying() {
        if playList.isEmpty { return }
        playList = playList.map { song in
            var mutableSong = song
            // 如果歌曲的文件路径与当前歌曲相同，则标记为正在播放
            mutableSong.isPlaying = (song.filePath == currentSong.filePath)
            return mutableSong
        }
    }

    // 更新播放列表中当前歌曲的“喜欢”状态
    func UpdateHeartChecked() {
        if let index = playList.firstIndex(where: { $0.filePath == currentSong.filePath }) {
            playList[index].isHeartChecked = currentSong.isHeartChecked
        }
    }

    // 修改播放列表中某一首歌的元数据
    func ChangeMetaDataOneOfList(changeOne: Song) {
        if let index = playList.firstIndex(where: { $0.id == changeOne.id }) { // 通过 ID 查找
            playList[index] = changeOne // 替换为新的歌曲信息
        }
    }

    // MARK: - AVAudioPlayerDelegate 代理方法

    // 音频播放完成时调用
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        flog.info("播放完成 (\(flag ? "成功" : "失败")): \(currentSong.filePath)")
        // isfinished = true // 考虑是否需要，或者让 UI 响应 isPlaying 变为 false
        isPlaying = false // 更新播放状态
        stopUpdateTimer() // 停止定时器
        PlayNext() // 自动播放下一首
        // isfinished = false
    }

    // 音频解码出错时调用
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        flog.error("音频播放器解码错误: \(error?.localizedDescription ?? "未知错误")")
        isPlaying = false // 更新播放状态
        stopUpdateTimer() // 停止定时器
        // 可选：播放下一首或显示错误信息给用户
    }

    // MARK: - 清理

    // 停止播放并清理所有相关资源
    func stopAndCleanup() {
        flog.debug("正在停止并清理播放器...")
        soudPlayer?.stop() // 停止播放
        isPlaying = false // 更新状态
        stopUpdateTimer() // 停止定时器
        soudPlayer = nil // 释放播放器实例
        currentSongDuration = nil // 重置时长
        reset() // 重置歌词等状态
        cancellables.forEach { $0.cancel() } // 取消所有 Combine 订阅
        cancellables.removeAll() // 清空订阅集合
        flog.debug("清理完成。")
    }
}
