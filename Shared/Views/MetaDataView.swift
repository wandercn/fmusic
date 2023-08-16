//
//  MetaDataView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/10.
//

import SwiftUI

struct MetaDataView: View {
    @Binding var song: Song
    @Binding var isShowMeta: Bool
    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("编辑元信息")
                    Image(systemName: "square.and.pencil")
                }
                .font(.headline)
                .foregroundColor(.orange)
            ) {
                VStack(alignment: .leading) {
                    Form {
                        TextField("歌曲名", text: $song.name)
                            .font(.body)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)
                        TextField("专辑", text: $song.album)
                            .font(.body)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)

                        TextField("艺术家", text: $song.artist)
                            .font(.body)
                            .padding(.vertical, 5)
                            .foregroundColor(.black)
                        HStack {
                            Button {
                                isShowMeta = false
                                _ = UpdateSongMeta(song: song)
                            } label: {
                                Text("保存".uppercased())
                                    .font(.headline) // 字体
                                    .fontWeight(.semibold) // 字体粗细
                            }
                            Spacer()
                            Button {
                                isShowMeta = false
                            } label: {
                                Text("取消".uppercased())
                                    .font(.headline) // 字体
                                    .fontWeight(.semibold) // 字体粗细
                            }
                        }
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .frame(width: 280, height: 300)
    }
}
