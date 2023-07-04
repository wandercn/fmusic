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

func GetMusicInfo(path: String) -> (Song, Image) {
    let url = URL(fileURLWithPath: path)
    let asset = AVURLAsset(url: url)
    var img = Image(systemName: "photo")
    var song = Song()
    for format in asset.availableMetadataFormats {
        print("format: \(format)")
        for metadata in asset.metadata(forFormat: format) {
            print("key= \(String(describing: metadata.commonKey)) value = \(String(describing: metadata.value))")
            if let commonKey = metadata.commonKey {
                let key = commonKey.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
                switch key {
                case "title":
                    song.name = metadata.value as! String
                case "albumName":
                    song.album = metadata.value as! String
                case "artist":
                    song.artist = metadata.value as! String
                case "artwork":
                    if let value = metadata.value {
                        img = Image(nsImage: NSImage(data: value as! Data)!)
                    }
                default:
                    continue
                }
            }
        }
    }
    return (song, img)
}

func GetMeta(path: String) -> Song {
    var s = Song()
    var prev: UnsafeMutablePointer<AVDictionaryEntry>?
    var dict = [String: String]()
    var fmt_ctx = avformat_alloc_context()
    let url: [CChar] = path.cString(using: .utf8)!
    if let fmt_ctx = get_format_ctx(url) {
        s.duration = TimeInterval(fmt_ctx.pointee.duration)
        s.filePath = path
        while let tag = av_dict_get(fmt_ctx.pointee.metadata, "", prev, AV_DICT_IGNORE_SUFFIX) {
            let key = String(cString: tag.pointee.key).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols).lowercased()
            let value = String(cString: tag.pointee.value).trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .symbols)
            dict[key] = value
            prev = tag
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
            print("KEY = \(k) Value= \(v)")
        }
    }
    avformat_close_input(&fmt_ctx)
    if s.name.isEmpty {
        s.name = URL(fileURLWithPath: path).lastPathComponent
    }
    return s
}
