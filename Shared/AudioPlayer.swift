//
//  AudioPlayer.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/19.
//

import AVFoundation
import Combine
import LyricsService 
import SwiftUI

enum PlayMode {
    case Loop // 列表循环
    case Order // 顺序播放
    case Random // 随机播放
    case Single // 单曲循环
}

func durationFormat(timeInterval: TimeInterval) -> String {
    let time = max(0, timeInterval)
    if !time.isFinite { return "00:00" }
    let interval = Int(time)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private let savedMusicDirsKey = "SavedMusicDirectories"
    private let playlistsKey = "SavedPlaylists"
    private let favoriteSongsKey = "FavoriteSongs"
    
    @Published var savedDirectories: [String] = [] { didSet { saveDirectories() } }
    @Published var playlists: [Playlist] = [] { didSet { savePlaylists() } }
    @Published var favoriteFilePaths: Set<String> = [] { didSet { saveFavorites() } }
    
    @Published var librarySongs: [Song] = []
    @Published var playbackQueue: [Song] = []
    @Published var currentSong = Song()
    @Published var isPlaying: Bool = false
    @Published var playMode: PlayMode = .Order
    @Published var volume: Float = 0.7 { didSet { soudPlayer?.volume = volume } }
    
    @Published var currentPlaylistIndex: Int = -1
    
    private var soudPlayer: AVAudioPlayer?
    @Published var albumCover = Image("album")
    @Published var currentSongDuration: TimeInterval? = nil
    
    @Published var lyricsParser = LyricsParser()
    @Published var currentLyrics = ""
    @Published var curLyricsIndex = -1
    @Published var curId = UUID()
    @Published var offsetTime: Double = 0
    @Published var currentWordIndex: Int? = nil
    @Published var currentWordProgress: Double = 0.0
    @Published var lyricsDir = NSHomeDirectory() + "/Music/Lyrics"
// --- Combine ---
private var updateTimer: Timer?
private let currentTimeSubject = PassthroughSubject<TimeInterval, Never>()
private var cancellables = Set<AnyCancellable>()
var currentTimePublisher: AnyPublisher<TimeInterval, Never> {
    currentTimeSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
}

override init() {
    super.init()
    loadDirectories()
    loadPlaylists()
    loadFavorites()
    reloadAllSavedDirectories()
    setupLyricsObserver()
}
private func setupLyricsObserver() {
    currentTimeSubject
        .receive(on: DispatchQueue.main)
        .sink { [weak self] time in
            self?.updateKaraokeProgress(currentTime: time)
        }
        .store(in: &cancellables)
}

// 计算卡拉OK进度的方法 ---
private func updateKaraokeProgress(currentTime: TimeInterval) {
    let currentLineIndex = curLyricsIndex
    guard
        currentLineIndex >= 0,
        currentLineIndex < lyricsParser.lyrics.count
    else {
        if currentWordIndex != nil || currentWordProgress != 0.0 {
            currentWordIndex = nil
            currentWordProgress = 0.0
        }
        return
    }

    let currentLine = lyricsParser.lyrics[currentLineIndex]

    // 确保 curId 同步，LyricsView 依赖 curId
    if curId != currentLine.id {
        curId = currentLine.id
    }

    let wordInfos = currentLine.wordInfos
    guard !wordInfos.isEmpty else {
        if currentWordIndex != nil || currentWordProgress != 0.0 {
            currentWordIndex = nil
            currentWordProgress = 0.0
        }
        return
    }

    let timeWithinLine = currentTime - currentLine.time + offsetTime
    var newWordIndex: Int? = nil
    var newWordProgress = 0.0

    if let foundIndex = wordInfos.lastIndex(where: { $0.startTime <= timeWithinLine }) {
        newWordIndex = foundIndex
        let currentWordInfo = wordInfos[foundIndex]
        if currentWordInfo.duration > 0 {
            let timeInWord = timeWithinLine - currentWordInfo.startTime
            newWordProgress = min(max(0.0, timeInWord / currentWordInfo.duration), 1.0)
        } else {
            newWordProgress = timeWithinLine >= currentWordInfo.startTime ? 1.0 : 0.0
        }
    }

    if currentWordIndex != newWordIndex || abs(currentWordProgress - newWordProgress) > 0.01 {
        currentWordIndex = newWordIndex
        currentWordProgress = newWordProgress
    }
}

    
    convenience init(path: String) {
        self.init()
        self.addDirectory(path)
        self.reloadAllSavedDirectories()
    }

    func play(song: Song, in queue: [Song]) {
        self.currentSong = song
        self.playbackQueue = queue
        PlayAudio(path: song.filePath)
    }

    func PlayAudio(path: String) {
        let url = URL(fileURLWithPath: path)
        do {
            soudPlayer = try AVAudioPlayer(contentsOf: url)
            soudPlayer?.delegate = self
            soudPlayer?.volume = volume
            soudPlayer?.prepareToPlay()
            soudPlayer?.play()
            isPlaying = true
            currentSongDuration = soudPlayer?.duration
            startUpdateTimer()
            
            if let img = GetAlbumCoverImage(path: path) { self.albumCover = img } else { self.albumCover = Image("album") }
            loadLyrics(songName: currentSong.name)
            
            flog.debug("开始播放: \(path)")
        } catch {
            flog.error("播放失败: \(error.localizedDescription)")
        }
    }

    func Play() {
        if let player = soudPlayer {
            player.play()
            isPlaying = true
            startUpdateTimer()
        } else if !currentSong.filePath.isEmpty {
            PlayAudio(path: currentSong.filePath)
        }
    }

    func Stop() {
        soudPlayer?.stop()
        isPlaying = false
        stopUpdateTimer()
        soudPlayer?.currentTime = 0
    }

    func Pause() {
        soudPlayer?.pause()
        isPlaying = false
        stopUpdateTimer()
    }

    func Resume() {
        Play()
    }

    func PlayNext() {
        guard !playbackQueue.isEmpty else { return }
        if let index = playbackQueue.firstIndex(where: { $0.id == currentSong.id }) {
            var nextIndex = index + 1
            if nextIndex >= playbackQueue.count {
                if playMode == .Loop { nextIndex = 0 } else { Stop(); return }
            }
            play(song: playbackQueue[nextIndex], in: playbackQueue)
        }
    }

    func PlayPrev() {
        guard !playbackQueue.isEmpty else { return }
        if let index = playbackQueue.firstIndex(where: { $0.id == currentSong.id }) {
            var prevIndex = index - 1
            if prevIndex < 0 { prevIndex = playbackQueue.count - 1 }
            play(song: playbackQueue[prevIndex], in: playbackQueue)
        }
    }

    func Duration() -> TimeInterval {
        return soudPlayer?.duration ?? 0
    }

    func CurrentTime() -> TimeInterval {
        return soudPlayer?.currentTime ?? 0
    }

    func SetCurrentTime(value: TimeInterval) {
        soudPlayer?.currentTime = value
        currentTimeSubject.send(value)
    }

    func SetVolume(value: Float) {
        self.volume = value
    }

    func UpdateHeartChecked() {
        // 记录或移除收藏路径
        if currentSong.isHeartChecked {
            favoriteFilePaths.insert(currentSong.filePath)
        } else {
            favoriteFilePaths.remove(currentSong.filePath)
        }
        // 更新所有列表中该歌曲的状态，并保存播放列表
        ChangeMetaDataOneOfList(changeOne: currentSong)
        savePlaylists()
    }

    func UpdatePlaying() {
        // 此逻辑现在通过 ID 匹配在 View 中实时实现，
        // 但为了兼容旧代码，我们可以触发一个刷新。
        objectWillChange.send()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag { PlayNext() }
    }

    func reloadAllSavedDirectories() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            var loadedSongs = [Song]()
            for dir in self.savedDirectories {
                let songs = self.scanFiles(at: dir)
                loadedSongs.append(contentsOf: songs)
            }
            let uniqueSongs = self.deduplicateAndSort(songs: loadedSongs)
            DispatchQueue.main.async {
                self.librarySongs = uniqueSongs
            }
        }
    }

    private func scanFiles(at path: String) -> [Song] {
        var results: [Song] = []
        let fm = FileManager.default
        let url = URL(fileURLWithPath: path)
        if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if ["mp3", "m4a", "flac", "wav"].contains(fileURL.pathExtension.lowercased()) {
                    var song: Song
                    if let s = GetMetadata(path: fileURL.path) {
                        song = s
                    } else {
                        song = Song(name: fileURL.deletingPathExtension().lastPathComponent, filePath: fileURL.path)
                    }
                    // 恢复收藏状态
                    song.isHeartChecked = favoriteFilePaths.contains(song.filePath)
                    results.append(song)
                }
            }
        }
        return results
    }

    private func deduplicateAndSort(songs: [Song]) -> [Song] {
        var seen = Set<String>()
        return songs.filter { seen.insert($0.filePath).inserted }.sorted { $0.name < $1.name }
    }

    func addDirectory(_ path: String) { if !savedDirectories.contains(path) { savedDirectories.append(path) } }
    func removeDirectory(at index: Int) { if index >= 0 && index < savedDirectories.count { savedDirectories.remove(at: index) } }

    func createPlaylist(name: String) -> Playlist {
        let p = Playlist(name: name)
        playlists.append(p)
        return p
    }
    
    func deletePlaylist(at index: Int) {
        if index >= 0 && index < playlists.count { playlists.remove(at: index) }
    }
    
    func addSongToPlaylist(_ song: Song, playlistIndex: Int) {
        if playlistIndex >= 0 && playlistIndex < playlists.count {
            var playlist = playlists[playlistIndex]
            playlist.addSong(song)
            playlists[playlistIndex] = playlist // 关键：重新赋值触发 @Published
            objectWillChange.send() // 双重保险
            savePlaylists()
        }
    }

    func removeSongFromPlaylist(playlistIndex: Int, songIndex: Int) {
        if playlistIndex >= 0 && playlistIndex < playlists.count {
            var playlist = playlists[playlistIndex]
            playlist.removeSong(at: songIndex)
            playlists[playlistIndex] = playlist // 重新赋值
            objectWillChange.send()
            savePlaylists()
        }
    }

    func renamePlaylist(at index: Int, newName: String) {
        if index >= 0 && index < playlists.count {
            var playlist = playlists[index]
            playlist.name = newName
            playlists[index] = playlist // 重新赋值
            objectWillChange.send()
            savePlaylists()
        }
    }

    func ChangeMetaDataOneOfList(changeOne song: Song) {
        if let index = librarySongs.firstIndex(where: { $0.id == song.id }) { librarySongs[index] = song }
        for i in 0..<playlists.count {
            if let index = playlists[i].songs.firstIndex(where: { $0.id == song.id }) { playlists[i].songs[index] = song }
        }
    }

    private func saveDirectories() { UserDefaults.standard.set(savedDirectories, forKey: savedMusicDirsKey) }
    private func loadDirectories() { savedDirectories = UserDefaults.standard.stringArray(forKey: savedMusicDirsKey) ?? [] }
    private func savePlaylists() { if let data = try? JSONEncoder().encode(playlists) { UserDefaults.standard.set(data, forKey: playlistsKey) } }
    private func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: playlistsKey), let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }
    
    private func saveFavorites() {
        let array = Array(favoriteFilePaths)
        UserDefaults.standard.set(array, forKey: favoriteSongsKey)
    }
    
    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: favoriteSongsKey) {
            favoriteFilePaths = Set(array)
        }
    }

    private func startUpdateTimer() {
        stopUpdateTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            if let player = self?.soudPlayer, player.isPlaying {
                self?.currentTimeSubject.send(player.currentTime)
            }
        }
    }
    private func stopUpdateTimer() { updateTimer?.invalidate(); updateTimer = nil }
    
    private func loadLyrics(songName: String) {
        let fm = FileManager.default
        let songUrl = URL(fileURLWithPath: currentSong.filePath)
        let localLrcPath = songUrl.deletingPathExtension().path + ".lrc"
        let globalLrcxPath = lyricsDir + "/" + songName + " - " + currentSong.artist + ".lrcx"
        let globalLrcPath = lyricsDir + "/" + songName + ".lrc"

        var content: String? = nil
        var loadedPath = ""

        if fm.fileExists(atPath: localLrcPath) {
            content = try? String(contentsOfFile: localLrcPath, encoding: .utf8)
            loadedPath = localLrcPath
        } else if fm.fileExists(atPath: globalLrcxPath) {
            content = try? String(contentsOfFile: globalLrcxPath, encoding: .utf8)
            loadedPath = globalLrcxPath
        } else if fm.fileExists(atPath: globalLrcPath) {
            content = try? String(contentsOfFile: globalLrcPath, encoding: .utf8)
            loadedPath = globalLrcPath
        }

        if let content = content {
            lyricsParser.parse(lyrics: content)
            flog.debug("歌词加载成功: \(loadedPath)")
            // 加载后立即触发一次进度更新
            updateKaraokeProgress(currentTime: CurrentTime())
        } else {
            lyricsParser = LyricsParser() // 加载失败，重置为空
            flog.debug("未找到歌词文件")
        }
    }
    
    func selectLibrary() { currentPlaylistIndex = -1 }
    func selectPlaylist(at index: Int) { currentPlaylistIndex = index }
}
