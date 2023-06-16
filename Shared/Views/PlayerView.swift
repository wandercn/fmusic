//
//  PlayerView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//
import SwiftUI

struct PlayerView: View {
    @State var isHeartChecked = false
    var body: some View {
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
            Text("04:52 / 04:56")
            
            Button(action: {
                self.isHeartChecked.toggle()
                print("点击了收藏")
            }) {
                Image(systemName: self.isHeartChecked ? "heart.circle.fill" : "heart.circle")
                    .font(.largeTitle)
                    .foregroundColor(self.isHeartChecked ?.pink : .secondary)
                
            }
            .buttonStyle(.borderless)
            
            Button {
                
            } label: {
                Image(systemName: "speaker.wave.2.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            
            Button {
                
            } label: {
                Image(systemName: "shuffle.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            
            Button {
                
            } label: {
                Image(systemName: "backward.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            
            Button {
                
            } label: {
                Image(systemName: "pause.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
            
            Button {
                
            } label: {
                Image(systemName: "forward.circle")
                    .font(.largeTitle)
            }
            .buttonStyle(.borderless)
        }.frame( height: 64 )
            .border(.secondary, width:1)
            .padding()
        
    }
}
