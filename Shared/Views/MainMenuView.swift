//
//  MainMenuView.swift
//  music (macOS)
//
//  Created by lsmiao on 2023/6/25.
//

import AVFoundation
import Foundation
import Logging
import SwiftUI

struct MainMenuView: Commands {
    @ObservedObject var player: AudioPlayer

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(action: {
                OpenSelectFolderWindws(player: player)
            }, label: {
                Text("导入音乐文件夹")
            }).keyboardShortcut("o")
            Button(action: {
                player.librarySongs.removeAll()
                player.savedDirectories.removeAll()
                player.Stop()
            }, label: {
                Text("清空资料库")
            }).keyboardShortcut("d")
        }
    }
}

// 根据文件扩展判断音频文件是否支持
let exts = [".flac", ".mp3", ".wav", ".m4a", ".aif", ".m4r"]
func IsAudioFileSupported(f: String) -> Bool {
    for ext in exts {
        if f.hasSuffix(ext) {
            return true
        }
    }
    return false
}

/// 打开文件夹选择对话框
func OpenSelectFolderWindws(player: AudioPlayer) {
    let openPanel = NSOpenPanel()
    openPanel.message = "选择音乐文件夹"
    openPanel.canChooseDirectories = true
    openPanel.allowsMultipleSelection = true
    openPanel.canChooseFiles = false
    openPanel.allowedContentTypes = [.folder]
    openPanel.begin { response in
        if response == .OK {
            DispatchQueue.global(qos: .userInteractive).async {
                var loadedSongs = [Song]()
                let urlsToProcess = openPanel.urls

                urlsToProcess.forEach { url in
                    let songsFromFolder = LoadFiles(dir: url.path)
                    loadedSongs.append(contentsOf: songsFromFolder)
                    DispatchQueue.main.async {
                        player.addDirectory(url.path)
                    }
                }

                let sortedSongs = loadedSongs.sorted { s1, s2 in
                    if s1.album == s2.album {
                        if s1.artist == s2.artist {
                            return s1.track < s2.track
                        }
                        return s1.artist < s2.artist
                    }
                    return s1.album < s2.album
                }

                DispatchQueue.main.async {
                    // 追加到曲库，并去重
                    var currentSongs = player.librarySongs
                    for song in sortedSongs {
                        if !currentSongs.contains(where: { $0.filePath == song.filePath }) {
                            currentSongs.append(song)
                        }
                    }
                    player.librarySongs = currentSongs.sorted { $0.name < $1.name }
                }
            }
        }
    }
}

func LoadFiles(dir: String) -> [Song] {
    var songs: [Song] = []
    var filePaths: [String] = []
    var subDirs: [String] = []

    let manager = FileManager.default
    do {
        subDirs = try manager.contentsOfDirectory(atPath: dir)
    } catch {
        flog.error("contentsOfDirectory\(dir) file: \(error)")
    }

    for sub in subDirs {
        let absPath = dir + "/" + sub
        if URL(fileURLWithPath: absPath).hasDirectoryPath {
            do {
                var files = try manager.subpathsOfDirectory(atPath: absPath)
                files = files.filter { IsAudioFileSupported(f: $0) }
                for f in files {
                    filePaths.append(absPath + "/" + f)
                }
            } catch {
                flog.debug("get \(absPath) fileNmae fail: \(error)")
            }
        } else {
            if IsAudioFileSupported(f: absPath) {
                filePaths.append(absPath)
            }
        }
    }

    for path in filePaths {
        if let song = GetMetadata(path: path) {
            songs.append(song)
        }
    }
    return songs
}

func GetMusicInfo(path: String) -> (Song, Image) {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    var img = Image("album")
    var song = Song()
    for format in asset.availableMetadataFormats {
        for metadata in asset.metadata(forFormat: .unknown) {
            if let commonKey = metadata.commonKey {
                let key = commonKey.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
                if let value = metadata.value {
                    switch key {
                    case "title": song.name = value.description
                    case "albumname": song.album = value.description
                    case "artist": song.artist = value.description
                    case "artwork": if let d = value as? Data, let ns = NSImage(data: d) { img = Image(nsImage: ns) }
                    default: continue
                    }
                }
            }
        }
    }
    song.duration = asset.duration.seconds
    song.filePath = path
    return (song, img)
}

func GetMetadata(path: String) -> Song? {
    var dict = [String: String]()
    var s = Song()
    var prev: UnsafeMutablePointer<AVDictionaryEntry>?
    var metadata = new_dict()
    guard let filename = path.cString(using: .utf8) else { return nil }
    var fmt_ctx = open_audio_file_fmt_ctx(filename)
    if let ctx = fmt_ctx {
        s.duration = TimeInterval(ctx.pointee.duration / Int64(AV_TIME_BASE))
        av_dict_copy(&metadata, fmt_ctx?.pointee.metadata, 0)
    }
    s.filePath = path
    while let tag = av_dict_get(metadata, "", prev, AV_DICT_IGNORE_SUFFIX) {
        let key = String(cString: tag.pointee.key).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
        let value = String(cString: tag.pointee.value).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols)
        dict[key] = value
        prev = tag
    }
    for (k, v) in dict {
        switch k {
        case "title": s.name = v
        case "album": s.album = v
        case "artist": s.artist = v
        case "track": s.track = (v as NSString).integerValue
        default: continue
        }
    }
    if s.name.isEmpty {
        var str = URL(fileURLWithPath: path).lastPathComponent
        for ext in exts { str = str.replacingOccurrences(of: ext, with: "") }
        s.name = str
    }
    avformat_close_input(&fmt_ctx)
    return s
}

func GetAlbumCoverImage(path: String) -> Image? {
    var img: Image?
    guard let pkt = get_album_cover_image(path) else { return nil }
    let data = pkt.pointee.data
    let size = pkt.pointee.size
    if data != nil {
        let nsData = NSData(bytes: data, length: Int(size))
        if let nsImage = NSImage(data: nsData as Data) { img = Image(nsImage: nsImage) }
    }
    av_packet_unref(pkt)
    av_free(pkt)
    return img
}

func UpdateSongMeta(song: Song) -> Bool {
    let filename = URL(fileURLWithPath: song.filePath).lastPathComponent
    let tmpFile = URL(fileURLWithPath: song.filePath).path.replacingOccurrences(of: filename, with: "") + "new" + filename
    var newMetaData = new_dict()
    av_dict_set(&newMetaData, "track", String(song.track).trimmingCharacters(in: .whitespaces), 0)
    av_dict_set(&newMetaData, "title", song.name.trimmingCharacters(in: .whitespaces), 0)
    av_dict_set(&newMetaData, "album", song.album.trimmingCharacters(in: .whitespaces), 0)
    av_dict_set(&newMetaData, "artist", song.artist.trimmingCharacters(in: .whitespaces), 0)
    if modify_meta(song.filePath, tmpFile, newMetaData) != 0 { return false }
    if replace_file(song.filePath, tmpFile) != 0 { return false }
    return true
}
