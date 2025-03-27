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

// MARK: - Helper Functions & Placeholders (Ensure these exist and are correct)

enum PlayMode {
    case Loop // 列表循环
    case Order // 顺序播放（播完停止或根据 nextSong 逻辑）
    case Random // 随机播放
    case Single // 单曲循环
}

// Placeholder for time formatting
func durationFormat(timeInterval: TimeInterval) -> String {
    let time = max(0, timeInterval)
    if !time.isFinite { return "00:00" }
    let interval = Int(time)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// Placeholder for fileExists check
func fileExists(atPath path: String) -> Bool {
    FileManager.default.fileExists(atPath: path)
}

// Placeholder for checkAndCreateDir
func checkAndCreateDir(dir: String) {
    // Implementation provided by user, seems okay
    if FileManager.default.fileExists(atPath: dir) {
        flog.debug("\(dir)目录已存在")
    } else {
        do {
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            flog.debug("\(dir)目录创建成功")
        } catch {
            flog.error("无法创建目录,错误：\(error)")
        }
    }
}

// Placeholder for nextSong / prevSong (ensure implementations are correct)
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

// Placeholder for searchLyrics external function
// Ensure Lyrics, LyricsSearchRequest, LyricsProviders are defined correctly via LyricsService
func searchLyrics(song: String, artist: String, timeout: Double, completion: @escaping ([Lyrics]?) -> Void) -> AnyCancellable? {
    flog.debug("Initiating lyrics search for \(song) - \(artist) (external function)")
    // --- User's Implementation ---
    let searchReq = LyricsSearchRequest(searchTerm: .info(title: song, artist: artist), duration: timeout)
    let provider = LyricsProviders.Group(service: [.syair, .gecimi, .kugou, .netease, .qq])
    var lyricsList: [Lyrics] = []
    let limitedTimePublisher = provider.lyricsPublisher(request: searchReq)
        .timeout(.seconds(timeout), scheduler: DispatchQueue.main)

    let cancellable = limitedTimePublisher.sink(
        receiveCompletion: { result in
            switch result {
            case .finished:
                flog.debug("Lyrics search finished normally. Count: \(lyricsList.count)")
                completion(lyricsList.isEmpty ? nil : lyricsList) // Return nil if empty for consistency?
            case .failure(let error):
                flog.error("Lyrics search failed or timed out: \(error)")
                completion(nil)
            }
        },
        receiveValue: { lyrics in
            flog.debug("Received lyrics fragment.")
            lyricsList.append(lyrics)
        }
    )
    return cancellable
    // --- End User's Implementation ---
}

// MARK: - AudioPlayer Class

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // --- Player Instance ---
    // @Published private var soudPlayer: AVAudioPlayer? // Publishing AVAudioPlayer directly can be tricky, make it private
    private var soudPlayer: AVAudioPlayer?

    // --- Playback State & Info ---
    @Published var playList: [Song] = .init()
    @Published var isPlaying: Bool = false
    @Published var isfinished: Bool = false // Consider if this is needed, delegate handles finish
    @Published var currentSong = Song()
    @Published var playMode: PlayMode = .Order
    @Published var volume: Float = 0.7 {
        didSet { // Update player volume when this changes
            soudPlayer?.volume = volume
        }
    }

    @Published var albumCover = Image("album") // Ensure "album" image exists in Assets

    // --- Duration Handling ---
    @Published var currentSongDuration: TimeInterval? = nil // Published duration

    // --- Lyrics ---
    @Published var lyricsParser = LyricsParser()
    @Published var currentLyrics = "" // Currently highlighted lyric text
    @Published var offsetTime: Double = 0 // Lyrics time offset
    @Published var curId = UUID() // ID of the currently highlighted lyric line
    @Published var curLyricsIndex = -1 // Index of the currently highlighted lyric line (-1 for none)
    @Published var lyricsDir = NSHomeDirectory() + "/Music/Lyrics" // Simplified path

    // --- Combine ---
    private var updateTimer: Timer?
    private let currentTimeSubject = PassthroughSubject<TimeInterval, Never>()
    private var cancellables = Set<AnyCancellable>() // Set to manage subscriptions

    var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentTimeSubject
            .receive(on: DispatchQueue.main) // Ensure subscribers receive on main thread
            .eraseToAnyPublisher()
    }

    // --- Initialization ---
    override init() {
        super.init()
        // Initial volume setting if needed, although didSet handles changes
        // soudPlayer?.volume = volume
        flog.debug("AudioPlayer initialized.")
    }

    // Convenience initializer (ensure LoadFiles is implemented)
    init(path: String) {
        super.init()
        playList = LoadFiles(dir: path)
        if let firstSong = playList.first {
            currentSong = firstSong
        }
        flog.debug("AudioPlayer initialized with path: \(path)")
    }

    deinit {
        flog.debug("AudioPlayer deinit.")
        stopAndCleanup() // Ensure cleanup on deinit
        // No need to manually cancel items in `cancellables` set
    }

    // MARK: - Playback Control Methods

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
        // Use the published duration property
        currentSongDuration ?? 1.0 // Default to 1.0 to avoid division by zero
    }

    func SetVolume(value: Float) {
        // Use the published volume property with didSet
        volume = min(max(value, 0.0), 1.0) // Clamp volume between 0 and 1
    }

    // Internal seek function
    private func seek(to time: TimeInterval) {
        guard let player = soudPlayer else { return }
        let duration = player.duration // Use player's duration for clamping seek time
        let validTime = max(0, min(time, duration))
        player.currentTime = validTime
        flog.debug("Seeked to time: \(validTime)")
        // Send immediate time update after seeking
        if !isPlaying { // If paused, send update manually as timer isn't running
            currentTimeSubject.send(validTime)
        }
        // If playing, timer will send update shortly
    }

    // MARK: - Core Audio Loading & Lyrics Handling

    func PlayAudio(path: String) {
        guard !path.isEmpty, fileExists(atPath: path) else {
            flog.error("PlayAudio failed: Path is empty or file does not exist at \(path)")
            // Optionally play next song or stop?
            return
        }

        let searchTimeOut: Double = 2
        let url = URL(fileURLWithPath: path)

        stopAndCleanup() // Stop previous player and timer first
        reset() // Reset lyrics state etc. for the new song

        do {
            soudPlayer = try AVAudioPlayer(contentsOf: url)
            soudPlayer?.delegate = self
            soudPlayer?.volume = volume // Apply current volume setting
            if soudPlayer?.prepareToPlay() == true {
                let playerDuration = soudPlayer?.duration ?? 0.0
                if playerDuration > 0 {
                    currentSongDuration = playerDuration // Update published duration
                    flog.debug("AVAudioPlayer prepared. Duration = \(playerDuration)")
                } else {
                    // Use song's potentially pre-loaded duration if player's isn't ready
                    currentSongDuration = currentSong.duration > 0 ? currentSong.duration : nil
                    flog.debug("AVAudioPlayer prepared, but duration not immediately available. Using: \(String(describing: currentSongDuration))")
                }
            } else {
                flog.error("AVAudioPlayer failed to prepare after init.")
                currentSongDuration = currentSong.duration > 0 ? currentSong.duration : nil // Fallback duration
            }

            // Start playing *after* setup
            if soudPlayer?.play() == true {
                isPlaying = true
                startUpdateTimer() // Start timer only after successful play
                flog.debug("AVAudioPlayer playing: \(path)")
                UpdatePlaying() // Update highlight in playlist
            } else {
                flog.error("AVAudioPlayer failed to play after prepare.")
                isPlaying = false
                stopUpdateTimer()
            }

        } catch {
            flog.error("Failed to initialize or play AVAudioPlayer for path \(path): \(error)")
            soudPlayer = nil
            isPlaying = false
            stopUpdateTimer()
            currentSongDuration = nil // Reset duration if loading failed
            return // Exit if player failed to load
        }

        // --- Lyrics Handling ---
        checkAndCreateDir(dir: lyricsDir)
        let lyricsFileName = "\(lyricsDir)/\(currentSong.name) - \(currentSong.artist).lrcx"

        if fileExists(atPath: lyricsFileName) {
            loadLyricsFromFile(path: lyricsFileName)
        } else {
            flog.debug("Lyrics file not found, attempting download: \(lyricsFileName)")
            // Cancel previous search if any
            cancellables.removeAll() // Example: Need a way to identify the lyrics search cancellable if stored in the set, or keep it separate. Let's keep it separate for simplicity here.
            // Alternative: Keep lyricsSearchCancellable separate if easier
            // lyricsSearchCancellable?.cancel() // Cancel previous one

            searchLyrics(song: currentSong.name, artist: currentSong.artist, timeout: searchTimeOut) { [weak self] docs in
                guard let self = self else { return }

                // Check if we are still playing the same song for which lyrics were requested
                let currentSongFileNameCheck = "\(self.lyricsDir)/\(self.currentSong.name) - \(self.currentSong.artist).lrcx"
                guard lyricsFileName == currentSongFileNameCheck else {
                    flog.debug("Lyrics arrived, but song has changed. Discarding.")
                    return
                }

                guard let firstDoc = docs?.first else {
                    flog.error("No lyrics found or docs array empty for: \(self.currentSong.name)")
                    return
                }

                let myData = firstDoc.description // Assuming Lyrics has a suitable description
                // Save to file
                do {
                    try myData.write(to: URL(fileURLWithPath: lyricsFileName), atomically: true, encoding: .utf8)
                    flog.debug("Lyrics data successfully written to file: \(lyricsFileName)")
                    // Load after saving
                    self.loadLyricsFromFile(path: lyricsFileName)
                } catch {
                    flog.error("Failed to write lyrics to file \(lyricsFileName): \(error)")
                }

            }? // Make the call return optional AnyCancellable
                .store(in: &cancellables) // Store the search subscription
        }
    }

    // Helper to load lyrics
    private func loadLyricsFromFile(path: String) {
        do {
            let lyricsString = try ReadFile(named: path)
            // Use async parsing if LyricsParser supports it or if parsing is heavy
            DispatchQueue.main.async { // Ensure parser update happens on main thread
                self.lyricsParser = LyricsParser(lyrics: lyricsString)
                flog.debug("Lyrics loaded successfully from: \(path)")
            }
        } catch {
            flog.error("Failed to read lyrics file \(path): \(error)")
            DispatchQueue.main.async {
                self.lyricsParser = LyricsParser() // Reset parser on failure
            }
        }
    }

    // Reset lyrics state
    private func reset() {
        offsetTime = 0
        currentLyrics = ""
        curLyricsIndex = -1 // Use -1 to indicate no line selected
        // Reset parser on main thread
        DispatchQueue.main.async {
            self.lyricsParser = LyricsParser()
        }
        flog.debug("Lyrics state reset.")
    }

    // MARK: - Timer Management

    private func startUpdateTimer() {
        guard updateTimer == nil else { return } // Prevent multiple timers
        stopUpdateTimer() // Ensure no lingering timer exists

        updateTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                           target: self,
                                           selector: #selector(timerFired),
                                           userInfo: nil,
                                           repeats: true)
        // Add to common RunLoop mode
        RunLoop.current.add(updateTimer!, forMode: .common)
        flog.debug("Update timer started.")
    }

    private func stopUpdateTimer() {
        if updateTimer != nil {
            updateTimer?.invalidate()
            updateTimer = nil
            flog.debug("Update timer stopped.")
        }
    }

    @objc private func timerFired() {
        guard let player = soudPlayer, isPlaying else {
            stopUpdateTimer() // Stop timer if player gone or not playing
            return
        }
        let currentTime = player.currentTime
        // flog.debug("AudioPlayer timerFired: Sending currentTime = \(currentTime)") // Optional: Verbose logging
        currentTimeSubject.send(currentTime)
    }

    // MARK: - Playlist Management (Basic stubs from user code)

    func UpdatePlaying() {
        if playList.isEmpty { return }
        playList = playList.map { song in
            var mutableSong = song
            mutableSong.isPlaying = (song.filePath == currentSong.filePath)
            return mutableSong
        }
    }

    func UpdateHeartChecked() {
        if let index = playList.firstIndex(where: { $0.filePath == currentSong.filePath }) {
            playList[index].isHeartChecked = currentSong.isHeartChecked
        }
    }

    func ChangeMetaDataOneOfList(changeOne: Song) {
        if let index = playList.firstIndex(where: { $0.id == changeOne.id }) {
            playList[index] = changeOne
        }
    }

    // MARK: - AVAudioPlayerDelegate Methods

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        flog.info("Playback finished (\(flag ? "successfully" : "unsuccessfully")): \(currentSong.filePath)")
        // isfinished = true // Let UI react to isPlaying becoming false instead?
        isPlaying = false
        stopUpdateTimer()
        PlayNext() // Delegate calls PlayNext automatically
        // isfinished = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        flog.error("Audio player decode error: \(error?.localizedDescription ?? "Unknown error")")
        isPlaying = false
        stopUpdateTimer()
        // Optionally play next or show error
    }

    // MARK: - Cleanup

    func stopAndCleanup() {
        flog.debug("Stopping and cleaning up player...")
        soudPlayer?.stop() // Stop playback
        isPlaying = false
        stopUpdateTimer() // Stop the timer
        soudPlayer = nil // Release the player instance
        currentSongDuration = nil // Reset duration
        reset() // Reset lyrics etc.
        cancellables.forEach { $0.cancel() } // Cancel any other Combine subs
        cancellables.removeAll()
    }
}
