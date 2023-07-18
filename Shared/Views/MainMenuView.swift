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
    @Binding var libraryList: [Song]
    @State private var urls: [URL] = []
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(action: {
                let openPanel = NSOpenPanel()
                openPanel.message = "选择音乐文件夹"
                openPanel.canChooseDirectories = true
                openPanel.allowsMultipleSelection = true
                openPanel.canChooseFiles = false
                openPanel.allowedContentTypes = [.folder]
                openPanel.begin { response in
                    if response == .OK {
                        urls = openPanel.urls
                        flog.debug("urls: \(urls)")
                        urls.forEach { url in
                            let songs = LoadFiles(dir: url.path)
                            libraryList.append(contentsOf: songs)
                        }
                    }
                }
            }, label: {
                Text("添加到资料库")
            })
        }
    }
}

// 根据文件扩展判断音频文件是否支持
func IsAudioFileSupported(f: String)-> Bool {
    let exts = [".flac", ".mp3", ".wav", ".m4a"]
    for ext in exts {
        if f.hasSuffix(ext) {
            return true
        }
    }
    return false
}

func LoadFiles(dir: String)->[Song] {
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
        flog.debug("sub: \(sub)")
        let absPath = dir + "/" + sub
        if URL(fileURLWithPath: absPath).hasDirectoryPath {
            do {
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
//    flog.logLevel = .debug
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
//    flog.logLevel = .debug

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
        default:
            continue
        }
    }

    if s.name.isEmpty {
        s.name = (URL(fileURLWithPath: path).lastPathComponent).replacingOccurrences(of: ".mp3", with: "")
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
