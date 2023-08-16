//
//  MainMenuView.swift
//  music (macOS)
//
//  Created by lsmiao on 2023/6/25.
//

import AVFoundation
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
                player.playList.removeAll()
            }, label: {
                Text("清空资料库")
            }).keyboardShortcut("d")
        }
    }
}

// 根据文件扩展判断音频文件是否支持
let exts = [".flac", ".mp3", ".wav", ".m4a", ".aif", ".m4r"]
func IsAudioFileSupported(f: String)-> Bool {
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
        //  异步函数无法return
        if response == .OK {
            var songs = [Song]()
            openPanel.urls.forEach { url in
                let s = LoadFiles(dir: url.path)
                songs.append(contentsOf: s)
            }
            player.playList.append(contentsOf: songs.sorted(by: { s1, s2 in
                s1.album > s2.album
            }))
        }
    }
}

func LoadFiles(dir: String)->[Song] {
    var songs: [Song] = []
    var filePaths: [String] = []
    var subDirs: [String] = []

    let manager = FileManager.default
    do {
        // 获取指定路径下的子目录，不递归。
        subDirs = try manager.contentsOfDirectory(atPath: dir)
    } catch {
        flog.error("contentsOfDirectory\(dir) file: \(error)")
    }

    for sub in subDirs {
        flog.debug("sub: \(sub)")
        let absPath = dir + "/" + sub
        if URL(fileURLWithPath: absPath).hasDirectoryPath {
            do {
                // 递归遍历读取子目录中的所有文件
                var files = try manager.subpathsOfDirectory(atPath: absPath)
                files = files.filter { x in
                    IsAudioFileSupported(f: x)
                }
                for f in files {
                    let file = absPath + "/" + f
                    let url = URL(fileURLWithPath: file)
                    flog.debug("File1 absPath: \(url.path)")
                    filePaths.append(url.path)
                }
            } catch {
                flog.debug("get \(absPath) fileNmae fail: \(error)")
            }
        } else {
            let url = URL(fileURLWithPath: absPath)
            if IsAudioFileSupported(f: url.path) {
                filePaths.append(url.path)
                flog.debug("File2 absPath: \(url.path)")
            } else {
                flog.info("Error absPath: \(url.path)")
            }
        }
    }

    for path in filePaths {
        flog.debug("path: \(path)")
        if let song = GetMetadata(path: path) {
            songs.append(song)
        }
    }
    return songs
}

// swift 原生方法获取mp3，aac,wav等苹果默认支持的音频元信息，内嵌专辑图片
func GetMusicInfo(path: String)->(Song, Image) {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    var img = Image("album")
    var song = Song()
    for format in asset.availableMetadataFormats {
        flog.debug("format: \(format)")
        for metadata in asset.metadata(forFormat: .unknown) {
            if let commonKey = metadata.commonKey {
                let key = commonKey.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
                flog.debug("key: \(key)")
                if let value = metadata.value {
                    flog.debug("value: \(value)")
                    switch key {
                    case "title":
                        song.name = value.description
                    case "albumName":
                        song.album = value.description
                    case "artist":
                        song.artist = value.description
                    case "artwork":
                        img = Image(nsImage: NSImage(data: value as! Data)!)
                    default:
                        continue
                    }
                }
            }
        }
    }

    song.duration = asset.duration.seconds
    song.filePath = path
    flog.debug("song = \(song)")
    return (song, img)
}

// 调用ffmpeAPI获取所有音频的元信息
func GetMetadata(path: String)->Song? {
    var dict = [String: String]()
    var s = Song()

    var prev: UnsafeMutablePointer<AVDictionaryEntry>?
    var metadata = new_dict()
    guard let filename = path.cString(using: .utf8) else {
        return nil
    }
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
        flog.debug("KEY = \(key) Value= \(value)")
    }
    for (k, v) in dict {
        switch k {
        case "title":
            s.name = v
        case "album":
            s.album = v
        case "artist":
            s.artist = v
        case "track":
            s.track = (v as NSString).integerValue
        default:
            continue
        }
    }

    if s.name.isEmpty {
        var str = (URL(fileURLWithPath: path).lastPathComponent)
        for ext in exts {
            flog.debug("ext: \(ext)")
            str = str.replacingOccurrences(of: ext, with: "")
        }
        flog.debug("str: \(str)")
        s.name = str
    }
    // 释放打开的音频文件
    avformat_close_input(&fmt_ctx)
    return s
}

// 调用ffmpegAPI获取音频内嵌专辑图片
func GetAlbumCoverImage(path: String) ->Image? {
    var img: Image?
    flog.debug("file: \(path)")
    guard let pkt = get_album_cover_image(path) else {
        return nil
    }
    withUnsafePointer(to: pkt) { ptr in
        flog.debug("pkt_addr4:\(ptr)")
    }
    let data = pkt.pointee.data
    let size = pkt.pointee.size
    flog.debug("data: \(String(describing: pkt.pointee.data))")

    flog.debug("size: \(pkt.pointee.size)")

    if data != nil {
        let nsData = NSData(bytes: data, length: Int(size))
        // 获取的data数据格式不正确，组装NSImage可能失败
        if let nsImage = NSImage(data: nsData as Data) {
            img = Image(nsImage: nsImage)
        } else {
            flog.info("nsImage为空")
        }
    }
    av_packet_unref(pkt)
    av_free(pkt)
    return img
}

// 修改音频文件的元信息
func UpdateSongMeta(song: Song)-> Bool {
    let filename = URL(fileURLWithPath: song.filePath).lastPathComponent
    let tmpFile = URL(fileURLWithPath: song.filePath).path.replacingOccurrences(of: filename, with: "") + "new" + filename
    flog.debug("tmpFile: \(tmpFile)")
    var newMetaData = new_dict()
    av_dict_set(&newMetaData, "title", song.name, 0)
    av_dict_set(&newMetaData, "album", song.album, 0)
    av_dict_set(&newMetaData, "artist", song.artist, 0)
    if modify_meta(song.filePath, tmpFile, newMetaData) != 0 {
        flog.error("modify_meta fail!")
        return false
    }
    if replace_file(song.filePath, tmpFile) != 0 {
        flog.error("replace_file fail!")
        return false
    }
    return true
}
