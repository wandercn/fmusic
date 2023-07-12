//
//  MainMenuView.swift
//  music (macOS)
//
//  Created by lsmiao on 2023/6/25.
//

import AVFoundation
import SwiftUI

struct MainMenuView: Commands {
    @Binding var libraryList: [Song]
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(action: {
                let openPanel = NSOpenPanel()
                openPanel.message = "选择音乐文件夹"
                openPanel.canChooseDirectories = false
                openPanel.allowsMultipleSelection = true
                openPanel.canChooseFiles = true
                openPanel.allowedContentTypes = [.audio]
                openPanel.begin { response in
                    if response == .OK {
                        print(openPanel.urls)
                        openPanel.urls.forEach { url in
                            let song = GetMeta(path: url.path)

                            libraryList.append(song)
                        }
                    }
                }
            }, label: {
                Text("添加到资料库")
            })
        }
    }
}

// swift 原生方法获取mp3，aac,wav等苹果默认支持的音频元信息，内嵌专辑图片
func GetMusicInfo(path: String)->(Song, Image) {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    var img = Image("album")
    var song = Song()
    for format in asset.availableMetadataFormats {
        print("format: \(format)")
        for metadata in asset.metadata(forFormat: .unknown) {
            if let commonKey = metadata.commonKey {
                let key = commonKey.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
                print("key: \(key)")
                if let value = metadata.value {
                    print("value: \(value)")
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
    print("song = \(song)")
    return (song, img)
}

// 调用ffmpeAPI获取所有音频的元信息
func GetMeta(path: String)->Song {
    var s = Song()
    var prev: UnsafeMutablePointer<AVDictionaryEntry>?
    var dict = [String: String]()
    var fmt_ctx = avformat_alloc_context()
    let url: [CChar] = path.cString(using: .utf8)!
    if let fmt_ctx = get_format_ctx(url) {
        s.duration = TimeInterval(fmt_ctx.pointee.duration / Int64(AV_TIME_BASE))
        s.filePath = path
        while let tag = av_dict_get(fmt_ctx.pointee.metadata, "", prev, AV_DICT_IGNORE_SUFFIX) {
            let key = String(cString: tag.pointee.key).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
            let value = String(cString: tag.pointee.value).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols)
            dict[key] = value
            prev = tag
            print("KEY = \(key) Value= \(value)")
        }

        for (k, v) in dict {
            switch k {
            case "title":
                s.name = v
            case "album":
                s.album = v
            case "artist":
                s.artist = v
            default: continue
            }
//            print("KEY = \(k) Value= \(v)")
        }
    }
    avformat_close_input(&fmt_ctx)
    if s.name.isEmpty {
        s.name = (URL(fileURLWithPath: path).lastPathComponent).replacingOccurrences(of: ".mp3", with: "")
    }
    return s
}

// 调用ffmpegAPI获取音频内嵌专辑图片
func GetCoverImg(path: String) ->Image? {
    var pkt = av_packet_alloc()
    var img: Image?
    print("file: \(path)")
    if get_cover_image(path, pkt) == -1 {
        return nil
    }
    let data = pkt?.pointee.data
    let size = pkt?.pointee.size
    print("i-data: \(String(describing: data!))")

    if data != nil {
        let nsData = NSData(bytes: data!, length: Int(size!))
//        print("nsData: \(nsData)")
        // 获取的data数据格式不正确，组装NSImage可能失败
        if let nsImage = NSImage(data: nsData as Data) {
            img = Image(nsImage: nsImage)
        }
    }
    av_packet_free(&pkt)
    return img
}
