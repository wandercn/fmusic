//
//  PlayerView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//
import SwiftUI
import AVFoundation
var soudPlayer: AVAudioPlayer?

enum PlayMode {
    case Loop
    case Order
    case Random
    case Single
}

struct PlayerView: View {
    @Binding var libraryList: [Song]
    @Binding var currnetSong: Song
    @State var playMode: PlayMode = .Order
    @State var modeImage: String = "list.bullet.circle"
    @State var autoPlay = true
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var isHeartChecked = false // 是否点击收藏
    @State var currtime:TimeInterval = 0.0 // 当前播放时长
    @State var totaltime: TimeInterval = 0.0 // 歌曲的总时长
    @State var percentage = 0.0 // 播放进度比率
    @State var isEditing = false // 是否手工拖动进度条
    @State var showPlayButton = true // 是否显示播放按钮图标，为false时，显示暂停按钮
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 64, height: 64)
                
                VStack(alignment: .leading) {
                    Text("七里香 - 周杰伦")
                        .foregroundColor(.secondary)
                    Text(URL(fileURLWithPath: self.currnetSong.filePath).lastPathComponent).padding(.top,5)
                }
                .onChange(of: self.currnetSong.filePath) { newValue in
                    //                    playAudio(path:self.currnetSong.filePath)
                    soudPlayer?.currentTime = 0
                    soudPlayer?.stop()
                    playAudio(path: self.currnetSong.filePath)
                    if let total = soudPlayer?.duration{
                        self.totaltime = total
                    }
                    self.showPlayButton = false
                    
                    if self.$libraryList.count > 0{
                        for index in 0..<self.$libraryList.count {
                            if self.libraryList[index].filePath == self.currnetSong.filePath{
                                self.libraryList[index].isPlaying = true
                            }else{
                                self.libraryList[index].isPlaying = false
                            }
                        }
                    }
                }
                Spacer()
                //            }
                // 播放进度条
                HStack {
                    
                    ProgressView(value: self.percentage,total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(Color.pink)
                    
                    
                    
                    //                    Slider(
                    //                        value:self.$percentage,
                    //                        in: 0...1,
                    //                        onEditingChanged: { editing in
                    //                            isEditing = editing
                    //                        }
                    //                    )
                        .onReceive(timer){_ in
                            if isEditing {
                                // 手工调整播放进度
                                soudPlayer?.currentTime = self.percentage * self.totaltime
                            } else {
                                if let currTime=soudPlayer?.currentTime{
                                    self.currtime = currTime
                                    self.percentage = self.currtime/self.totaltime
                                }
                            }
                            // 播放完成
                            if let player = soudPlayer{
                                let old = self.currnetSong
                                if !player.isPlaying && self.autoPlay && !self.showPlayButton{
                                    print("isplaying: \(player.isPlaying)")
                                    print("autoPlay: \(self.autoPlay)")
                                    self.currnetSong = nextSong(currSong: old, playList:self.libraryList,playMode: self.playMode)
                                    // 单曲循环模式特殊处理
                                    if self.playMode == .Single{
                                        soudPlayer?.currentTime = 0
                                        soudPlayer?.play()
                                        self.showPlayButton = false
                                    }
                                }
                            }
                            
                            
                        }
                    
                    //
                    //
                    // 显示当前播放时长
                    Text(durationFormat(timeInterval:  self.currtime) + " / " + durationFormat( timeInterval: self.totaltime))
                }.frame(width: 300)
                
                Button(action: {
                    self.isHeartChecked.toggle()
                    print("点击了收藏")
                }) {
                    Image(systemName: self.isHeartChecked ? "heart.circle.fill" : "heart.circle")
                        .font(.largeTitle)
                    //                        .foregroundColor(self.isHeartChecked ?.red : .secondary)
                        .pinkBackgroundOnHover()
                    
                    
                }
                .buttonStyle(.borderless)
                
                Button(action:{
                    
                }) {
                    Image(systemName: "speaker.wave.2.circle")
                        .font(.largeTitle)
                }
                .buttonStyle(.borderless)
                .pinkBackgroundOnHover()
                
                Button(action:{
                    let old = self.playMode
                    print("old playMode: \(old)")
                    ( self.playMode , self.modeImage) = nextPlayMode(mode: old)
                    print("new playMode: \(self.playMode)")
                }) {                    Image(systemName: self.modeImage)
                        .font(.largeTitle)
                    
                }
                .buttonStyle(.borderless)
                .pinkBackgroundOnHover()
                // 媒体播放控制按钮
                HStack{
                    // 上一曲按钮
                    Button(action:{
                        let old = self.currnetSong
                        self.currnetSong = prevSong(currSong: old, playList:self.libraryList,playMode: self.playMode)
                    })  {
                        Image(systemName: "backward.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()
                    // 播放/暂停按钮
                    Button(action:{
                        if self.showPlayButton{
                            if self.currtime == 0 {
                                //                                playAudio(path:"/Users/lsmiao/Downloads/ACC格式音乐/10.温暖的想念.m4a")
                                if self.currnetSong.filePath.isEmpty && !self.libraryList.isEmpty{
                                    self.currnetSong = self.libraryList.first!
                                }
                                playAudio(path:self.currnetSong.filePath)
                                if let total =  soudPlayer?.duration{
                                    self.totaltime = total
                                }}
                            else{
                                // 当前播放时长大于0 表示暂停，恢复播放就行。
                                soudPlayer?.play()
                            }
                        }else{
                            soudPlayer?.pause()
                        }
                        // 切换显示按钮
                        self.showPlayButton.toggle()
                        
                    })  {
                        Image(systemName: self.showPlayButton ? "play.circle" : "pause.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()
                    
                    // 下一曲按钮
                    Button(action:{
                        let old = self.currnetSong
                        self.currnetSong = nextSong(currSong: old, playList:self.libraryList,playMode: self.playMode)
                    })  {
                        Image(systemName: "forward.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
                    .pinkBackgroundOnHover()
                }
            }.frame( height: 64 )
                .padding()
                .background(RoundedRectangle(cornerSize: CGSize.zero)
                    .fill(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                )
                .foregroundColor(Color.secondary)
        }
        
    }
}


func playAudio(path: String){
    let url = URL(fileURLWithPath: path)
    do {
        soudPlayer = try AVAudioPlayer(contentsOf: url)
        soudPlayer?.play()
        
    } catch {
        print("读取音频文件失败")
    }
}

func nextPlayMode(mode: PlayMode)->(playMode: PlayMode,image: String){
    switch mode {
    case .Loop:
        return (.Order,"list.bullet.circle")
    case .Order:
        return (.Random , "shuffle.circle")
    case .Random:
        return (.Single,"repeat.1.circle")
    case .Single:
        return (.Loop , "repeat.circle")
    default:
        return (.Order,"list.bullet.circle")
    }
}

func nextSong(currSong: Song, playList:[Song] ,playMode: PlayMode) -> Song{
    switch playMode {
    case .Loop:
        print(PlayMode.Loop)
        for index in 0..<playList.count{
            if currSong.filePath == playList[index].filePath{
                return playList[ index+1 > playList.count ? 0 : index+1 ]
            }
        }
    case .Order:
        print(PlayMode.Order)
        for index in 0..<playList.count{
            if index+1 > playList.count {
                soudPlayer?.stop()
            }
            if currSong.filePath == playList[index].filePath{
                return playList[ index+1 >= playList.count ? index : index+1 ]
            }
        }
    case .Random:
        print(PlayMode.Random)
        let nextId = Int.random(in: 0...(playList.count - 1 ))
        return playList[nextId]
        
    case .Single:
        print(PlayMode.Single)
        
        return currSong
        
    }
    
    return currSong
    
}

func prevSong(currSong: Song, playList:[Song] ,playMode: PlayMode) -> Song{
    switch playMode {
    case .Loop:
        print(PlayMode.Loop)
        for index in 0..<playList.count{
            if currSong.filePath == playList[index].filePath{
                return playList[ index - 1 < 0 ? 0 : index - 1 ]
            }
        }
    case .Order:
        print(PlayMode.Order)
        for index in 0..<playList.count{
            if index - 1 < 0 {
                soudPlayer?.stop()
            }
            if currSong.filePath == playList[index].filePath{
                return playList[ index - 1 < 0 ? 0 : index - 1 ]
            }
        }
    case .Random:
        print(PlayMode.Random)
        let nextId = Int.random(in: 0...(playList.count - 1 ))
        return playList[nextId]
        
    case .Single:
        print(PlayMode.Single)
        
        return currSong
        
    }
    
    return currSong
    
}

func durationFormat(timeInterval:TimeInterval) -> String{
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.pad]
    return formatter.string(from: timeInterval)!
}


