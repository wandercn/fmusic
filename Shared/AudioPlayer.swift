//
//  AppDelegate.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/19.
//

import AVFoundation
import Cocoa
import Combine
import Foundation
import LyricsService
import SwiftUI
enum PlayMode {
    case Loop
    case Order
    case Random
    case Single
}

class AudioPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private var soudPlayer: AVAudioPlayer?
    @Published var playList: [Song] = .init()
    @Published var isfinished: Bool = false
    @Published var currentSong = Song()
    @Published var playMode: PlayMode = .Order
    @Published var volume: Float = 0.7
    @Published var albumCover = Image("album")
    @Published var lyricsParser = LyricsParser()
    @Published var currentLyrics = ""
    @Published var offsetTime: Double = 0
    @Published var curId = UUID()
    @Published var curLyricsIndex = 0
    @Published var lyricsDir = "/"+NSHomeDirectory().split(separator: "/")[0 ... 1].joined(separator: "/")+"/Music/Lyrics" // ~/Music
    // AnyCancellable必须在对象中生命周期时间够长，如果在函数中还没等网络请求结束就取消了
    @Published var lyricsSearchCancellable: AnyCancellable?
    override init() {
        super.init()
    }

    init(path: String) {
        super.init()
        playList = LoadFiles(dir: path)
        currentSong = playList.first!
    }

    func UpdatePlaying() {
        if playList.count > 0 {
            for index in 0 ..< playList.count {
                if playList[index].filePath == currentSong.filePath {
                    playList[index].isPlaying = true
                } else {
                    playList[index].isPlaying = false
                }
            }
        }
    }

    func UpdateHeartChecked() {
        if playList.count > 0 {
            for index in 0 ..< playList.count {
                if playList[index].filePath == currentSong.filePath {
                    playList[index].isHeartChecked = currentSong.isHeartChecked
                    return
                }
            }
        }
    }

    func ChangeMetaDataOneOfList(changeOne: Song) {
        let current = playList.firstIndex { song in
            song.id == changeOne.id
        }
        guard let index = current else {
            return
        }
        playList[index] = changeOne
    }

    func PlayFirst() {
        if currentSong.filePath.isEmpty, !playList.isEmpty {
            currentSong = playList.first!
        }
        PlayAudio(path: currentSong.filePath)
        if let total = soudPlayer?.duration {
            currentSong.duration = total
        }
    }

    func reset() {
        // 更换歌曲，歌词时间偏移量重置为0
        offsetTime = 0
        currentLyrics = ""
        curLyricsIndex = 0
        // 切换歌曲，歌词重置为空
        lyricsParser = LyricsParser()
    }

    func PlayAudio(path: String) {
        let searchTimeOut: Double = 2
        let url = URL(fileURLWithPath: path)
        do {
            soudPlayer?.stop()
            soudPlayer = try AVAudioPlayer(contentsOf: url)
            soudPlayer?.prepareToPlay()
            soudPlayer?.play()
            soudPlayer?.delegate = self
        } catch {
            flog.error("读取音频文件失败:\(path) error: \(error)")
        }
        // 重置记录数据
        reset()
        // 检查创建歌词存储目录
        checkAndCreateDir(dir: lyricsDir)
        // 下载歌词
        let lyricsFileName = "\(lyricsDir)/\(currentSong.name) - \(currentSong.artist).lrcx"

        guard !fileExists(atPath: lyricsFileName) else {
            // 1.歌词文件存在马上加载歌词
            guard let str = try? ReadFile(named: lyricsFileName) else {
                flog.debug("\(currentSong.name) - \(currentSong.artist).lrcx 歌词文件不存在")
                return
            }
            lyricsParser = LyricsParser(lyrics: str)
            return
        }
        // 2. 歌词文件不存在，等下载完成，再读取歌词文件
        flog.debug("正在下载歌词: \(lyricsFileName)")
        // 网络搜索歌词
        lyricsSearchCancellable = searchLyrics(song: currentSong.name, artist: currentSong.artist, timeout: searchTimeOut) { [self] docs in
            guard let docs = docs else {
                flog.error("没有搜索到歌词:\(currentSong.name) - \(currentSong.artist)")
                return
            }
            guard let firstDoc = docs.first else {
                flog.error("搜索到歌词，但结果为空数组: \(currentSong.name) - \(currentSong.artist)")
                return
            }
            let myData = firstDoc.description
            let url = URL(fileURLWithPath: lyricsFileName)
            guard let outputStream = OutputStream(url: url, append: true) else {
                flog.error("无法创建文件输出流: \(lyricsFileName)")
                return
            }

            outputStream.open()
            defer { outputStream.close() } // 确保关闭

            let bytesWritten = outputStream.write(myData, maxLength: myData.utf8.count)
            guard bytesWritten > 0 else {
                flog.error("歌词写入失败: \(lyricsFileName)")
                return
            }
            flog.debug("数据已成功写入文件:\(lyricsFileName)")

            // 当前在异步函数中等歌词下载完成，再读取歌词文件
            // 检查是否为当前歌曲的歌词（防止切歌后误加载）
            let currentSongLyricsFileName = "\(lyricsDir)/\(currentSong.name) - \(currentSong.artist).lrcx"
            guard lyricsFileName == currentSongLyricsFileName else {
                flog.debug("歌词文件已过期（用户可能已切歌）")
                return
            }

            // 加载歌词
            guard let str = try? ReadFile(named: lyricsFileName) else {
                flog.debug("\(currentSong.name) - \(currentSong.artist).lrcx 歌词文件不存在")
                return
            }
            lyricsParser = LyricsParser(lyrics: str)
        }
    }

    func PlayNext() {
        if currentSong.filePath.isEmpty {
            PlayFirst()
            return
        }
        let old = currentSong
        currentSong = nextSong(currentSong: old, playList: playList, playMode: playMode)
        // 单曲循环模式特殊处理
        if playMode == .Single {
            soudPlayer?.currentTime = 0
            soudPlayer?.play()
        }
        PlayAudio(path: currentSong.filePath)
    }

    func PlayPrev() {
        if currentSong.filePath.isEmpty {
            PlayFirst()
            return
        }
        let old = currentSong
        currentSong = prevSong(currentSong: old, playList: playList, playMode: playMode)
        // 单曲循环模式特殊处理
        if playMode == .Single {
            soudPlayer?.currentTime = 0
            soudPlayer?.play()
        }
        PlayAudio(path: currentSong.filePath)
    }

    func Stop() {
        soudPlayer?.stop()
    }

    func Pause() {
        soudPlayer?.pause()
    }

    func Play() {
        if soudPlayer?.currentTime == nil {
            PlayFirst()
        } else {
//            当前播放时长不为空表示暂停，恢复播放就行。
            soudPlayer?.play()
        }
    }

    func SetCurrentTime(value: TimeInterval) {
        soudPlayer?.currentTime = value
    }

    func CurrentTime() -> TimeInterval {
        guard let currentTime = soudPlayer?.currentTime else {
            return 0
        }
        return currentTime
    }

    func Duration() -> TimeInterval {
        guard let duration = soudPlayer?.duration else {
            return 0
        }
        return duration
    }

    func SetVolume(value: Float) {
        volume = value
        soudPlayer?.setVolume(volume, fadeDuration: 0)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        flog.info("播放完成: \(currentSong.filePath)")
        isfinished = true
        PlayNext()
        isfinished = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        flog.info("播放出错: \(String(describing: error))")
    }

    /// 返回下一曲的歌曲信息，根据不同的播放模式返回不同
    func nextSong(currentSong: Song, playList: [Song], playMode: PlayMode) -> Song {
        if currentSong.filePath.isEmpty {
            return currentSong
        }
        // 先找到当前播放歌曲的索引
        let current = playList.firstIndex { song in
            song.filePath == currentSong.filePath
        }
        guard let index = current else {
            return currentSong
        }
        // 计算下一歌曲的索引
        var next = index+1 >= playList.count ? 0 : index+1
        let ordernext = index+1 >= playList.count ? index : index+1

        switch playMode {
        case .Loop:
            flog.debug("循环播放模式:\(PlayMode.Loop)")
            return playList[next]
        case .Order:
            flog.debug("顺序播放模式:\(PlayMode.Order)")
            if index+1 > playList.count {
                soudPlayer?.stop()
            }
            return playList[ordernext]
        case .Random:
            flog.debug("随机播放模式:\(PlayMode.Random)")
            next = Int.random(in: 0 ... (playList.count - 1))
            return playList[next]

        case .Single:
            flog.debug("单曲循环播放模式:\(PlayMode.Single)")
            return currentSong
        }
    }

    /// 返回上一曲的歌曲信息，根据不同的播放模式返回不同
    func prevSong(currentSong: Song, playList: [Song], playMode: PlayMode) -> Song {
        if currentSong.filePath.isEmpty {
            return currentSong
        }
        // 先找到当前播放歌曲的索引
        let current = playList.firstIndex { song in
            song.filePath == currentSong.filePath
        }
        guard let index = current else {
            return currentSong
        }
        // 计算上一歌曲的索引
        var prev = index - 1 <= 0 ? 0 : index - 1

        switch playMode {
        case .Loop:
            flog.debug("循环播放模式:\(PlayMode.Loop)")
            return playList[prev]
        case .Order:
            flog.debug("顺序播放模式:\(PlayMode.Order)")
            return playList[prev]
        case .Random:
            flog.debug("随机播放模式:\(PlayMode.Random)")
            // 随机播放模式
            prev = Int.random(in: 0 ... (playList.count - 1))
            return playList[prev]
        case .Single:
            flog.debug("单曲循环播放模式:\(PlayMode.Single)")
            return currentSong
        }
    }

    deinit {
        // 这里显式调用取消订阅cancel()不是必须的，因为对象销毁会自动取消
        lyricsSearchCancellable?.cancel()
        flog.debug("AudioPlayer deinit, cancelling lyricsSearchCancellable.")
    }
}

func fileExists(atPath path: String) -> Bool {
    let fileManager = FileManager.default

    if let attributes = try? fileManager.attributesOfItem(atPath: path) {
        return attributes[.type] as? FileAttributeType == FileAttributeType.typeRegular
    }
    return false
}

func checkAndCreateDir(dir: String) {
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

func searchLyrics(song: String, artist: String, timeout: Double, completion: @escaping ([Lyrics]?) -> Void) -> AnyCancellable? {
    let searchReq = LyricsSearchRequest(searchTerm: .info(title: song, artist: artist), duration: timeout)

    let provider = LyricsProviders.Group(service: [.syair, .gecimi, .kugou, .netease, .qq])
    var lyricsList: [Lyrics] = []
    // 创建一个发布者，用于在指定时间内收集结果
    let limitedTimePublisher = provider.lyricsPublisher(request: searchReq)
        .timeout(.seconds(timeout), scheduler: DispatchQueue.main)

    // 订阅发布者
    let cancellable = limitedTimePublisher.sink(
        receiveCompletion: { result in
            switch result {
            case .finished:
                // 正常完成，返回收集到的歌词
                flog.debug("正常完成lyricsList：\(lyricsList)")
                completion(lyricsList)
            case .failure(let error):
                // 发生错误或超时，返回空
                flog.error("发生错误或超时\(error)")
                completion(nil)
            }
        },
        receiveValue: { lyrics in
            // 将每一条歌词添加到数组中
            lyricsList.append(lyrics)
        }
    )

    return cancellable
}
