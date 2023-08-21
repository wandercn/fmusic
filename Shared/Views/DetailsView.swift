//
//  DetailsView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/21.
//

import SwiftUI

struct DetailsView: View {
    @Binding var song: Song
    @Binding var isShowDetails: Bool
    @State private var newName: String = ""
    @State private var newFile: String = ""
    @State private var isShowAlert: Bool = false
    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("文件详情")
                    Image(systemName: "info.circle")
                }
                .font(.headline)
                .foregroundColor(.green)
            ) {
                VStack(alignment: .leading) {
                    Form {
                        HStack {
                            Text("Track:")
                            Text(song.track.description)
                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        HStack {
                            Text("歌曲名:")
                            Text(song.name)
                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        HStack {
                            Text("专辑:")
                            Text(song.album)
                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))

                        HStack {
                            Text("艺术家:")
                            Text(song.artist)
                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        HStack {
                            Text("时长:")
                            Text(durationFormat(timeInterval: song.duration))
                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        HStack {
                            Text("文件路径:")
                            Text(song.filePath)

                            Spacer()
                        }
                        .font(.body)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                    }
                    HStack(alignment: .center) {
                        Spacer()
                        Button {
                            isShowDetails = false
                            isShowAlert = false
                        } label: {
                            Text("关闭")
                                .font(.headline) // 字体
                                .fontWeight(.semibold) // 字体粗细
                                .foregroundColor(.white) // 前景颜色
                                .padding(8) // 内边距
                                // 背景
                                .background(
                                    Color.red
                                        .cornerRadius(10) // 圆角半径
                                )
                        }
                        .buttonStyle(.borderless)

                        Spacer()
                    }
                    GroupBox(label: Text("文件重命名").font(.headline)) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("原文件名:")
                            Spacer()
                            Text(URL(fileURLWithPath: song.filePath).lastPathComponent)
                            Spacer()
                        }
                        HStack {
                            TextField("新文件名", text: $newName)
                            Text("." + URL(fileURLWithPath: song.filePath).pathExtension)
                        }
                        Spacer()
                        HStack {
                            Button {
                                var old = URL(fileURLWithPath: song.filePath).pathComponents
                                let ext = URL(fileURLWithPath: song.filePath).pathExtension
                                old.removeLast()
                                old.append(newName + "." + ext)
                                newFile = old.joined(separator: "/")

                                if rename(song.filePath, newFile) == 0 {
                                    isShowDetails = false
                                    song.filePath = newFile
                                } else {
                                    isShowAlert = true
                                }
                            } label: {
                                Text("重命名")
                                    .font(.headline) // 字体
                                    .fontWeight(.semibold) // 字体粗细
                                    .foregroundColor(.white) // 前景颜色
                                    .padding(8) // 内边距
                                    // 背景
                                    .background(
                                        Color.accentColor
                                            .cornerRadius(10) // 圆角半径
                                    )
                            }
                            .alert(isPresented: $isShowAlert) {
                                Alert(title: Text("重命名失败"),
                                      message: Text("\(URL(fileURLWithPath: song.filePath).lastPathComponent)\n重命名为\n\(URL(fileURLWithPath: newFile).lastPathComponent)失败！"),
                                      dismissButton: .default(Text("返回")))
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1))
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 500, maxWidth: 1024, minHeight: 500, maxHeight: 768)
    }
}
