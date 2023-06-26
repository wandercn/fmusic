//
//  MainMenuView.swift
//  music (macOS)
//
//  Created by lsmiao on 2023/6/25.
//

import SwiftUI

struct MainMenuView: Commands {
//    @Binding var paths : [String]
    @Binding  var libraryList:[Song]
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
                            let p = url.path
                            print(url.path)
                            let s = Song(name:p , artist:"未知", album: "未知", duration: TimeInterval(300), filePath: p,isSelected: false)
                            self.libraryList.append(s)
//                            paths.append(url.path)
                        }
                    }
                }
            }, label: {
              Text("添加到资料库")
            })
        }
    }
}

//struct MainMenuView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainMenuView()
//    }
//}
