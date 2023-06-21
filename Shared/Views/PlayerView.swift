//
//  PlayerView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//
import SwiftUI
import AVFoundation
var soudPlayer: AVAudioPlayer?

struct PlayerView: View {
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
                    Text("你是我唯一想要的了解").padding(.top,5)
                }
                Spacer()
                // 播放进度条
                HStack {
                    
//                    ProgressView(value: self.percentage,total: 1.0)
//                        .progressViewStyle(.linear)
                    
                    Slider(
                        value:self.$percentage,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
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
                        }
                        
                        
                    // 显示当前播放时长
                    Text(durationFormat(timeInterval:  self.currtime) + " / " + durationFormat( timeInterval: self.totaltime))
                }.frame(width: 300)
                
                Button(action: {
                    self.isHeartChecked.toggle()
                    print("点击了收藏")
                }) {
                    Image(systemName: self.isHeartChecked ? "heart.circle.fill" : "heart.circle")
                        .font(.largeTitle)
                        .foregroundColor(self.isHeartChecked ?.pink : .secondary)
                    
                }
                .buttonStyle(.borderless)
                
                Button(action:{
                    
                }) {
                    Image(systemName: "speaker.wave.2.circle")
                        .font(.largeTitle)
                }
                .buttonStyle(.borderless)
                
                Button(action:{
                    
                }) {
                    Image(systemName: "shuffle.circle")
                        .font(.largeTitle)
                }
                .buttonStyle(.borderless)
                // 媒体播放控制按钮
                HStack{
                    // 上一曲按钮
                Button(action:{
                    self.currtime = 0
                })  {
                    Image(systemName: "backward.circle")
                        .font(.largeTitle)
                }
                .buttonStyle(.borderless)

                    // 播放/暂停按钮
                    Button(action:{
                        if self.showPlayButton{
                            if self.currtime == 0 {
                                playAudio(path:"/Users/lsmiao/Downloads/ACC格式音乐/10.温暖的想念.m4a")
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
                    // 下一曲按钮
                    Button(action:{
                        self.currtime = 0
                    })  {
                        Image(systemName: "forward.circle")
                            .font(.largeTitle)
                    }
                    .buttonStyle(.borderless)
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

func durationFormat(timeInterval:TimeInterval) -> String{
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .positional
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.pad]
    return formatter.string(from: timeInterval)!
}
