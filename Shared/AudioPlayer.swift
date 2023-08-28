//
//  AppDelegate.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/19.
//

import AVFoundation
import Foundation
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
    @Published var curId: UUID = .init()

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

    func PlayAudio(path: String) {
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
            next = Int.random(in: 0...(playList.count - 1))
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
            prev = Int.random(in: 0...(playList.count - 1))
            return playList[prev]
        case .Single:
            flog.debug("单曲循环播放模式:\(PlayMode.Single)")
            return currentSong
        }
    }
}
