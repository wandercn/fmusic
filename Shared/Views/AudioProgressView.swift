//
//  AudioProgressView.swift
//  music
//
//  Created by lsmiao on 2023/6/20.
//
import SwiftUI
import AVFoundation
//var soudPlayer: AVAudioPlayer?

struct AudioProgressView: View {
//    @State private var downloadAmount = 0.0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var currtime:TimeInterval = 0.0
    @State var totaltime: TimeInterval = 0.0
    @State var percentage = 0.0
    @State var isEditing = false
    var body: some View {
//        VStack {
//            ProgressView("正在下载...", value: downloadAmount, total: 100)
//                .onReceive(timer) { _ in
//                    if downloadAmount < 100 {
//                        downloadAmount += 2
//                    }
//                }
//        }
//        .padding()
//        Button {
//
//                      
//        } label: {
//        Image(systemName: "play")
//        }
        HStack{
            Slider(
                value:self.$percentage,
                        in: 0...1,
                        onEditingChanged: { editing in
                            isEditing = editing
                        }
                    )
            .onReceive(timer){_ in
                
                if isEditing {
                    soudPlayer?.currentTime = self.percentage * self.totaltime
                }else{
                if let currTime=soudPlayer?.currentTime{
                    self.currtime = currTime
                    self.percentage = self.currtime/self.totaltime
                }
                }
            }
            Text("\(durationFormat(timeInterval: self.currtime))")
//                        .foregroundColor(isEditing ? .red : .blue)
        }
        Text(durationFormat(timeInterval:  self.currtime) + "/" + durationFormat( timeInterval: self.totaltime))


    }
}

struct AudioProgressView_Previews: PreviewProvider {
    static var previews: some View {
        AudioProgressView()
    }
}




