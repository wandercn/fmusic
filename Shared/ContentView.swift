//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
//    @Binding var paths: [String]
    @State var currnetSong: Song = Song(name: "", artist: "", album: "", duration: TimeInterval(0), filePath: "", isSelected: false)
    @Binding  var libraryList:[Song]
//    @State var librayList = [
//        Song(name: "阳光宅男1", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男2", artist: "周杰伦2", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男3", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男4", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男5", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男6", artist: "周杰伦", album: "我很忙2", duration: 233,isSelected: false),
//        Song(name: "阳光宅男7", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男8", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男9", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男10", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男11", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男12", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男13", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男14", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男15", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男16", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男17", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男18", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男19", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男20", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//        Song(name: "阳光宅男21", artist: "周杰伦", album: "我很忙", duration: 233,isSelected: false),
//    ]
    
    var body: some View {
        VStack{
            Spacer()
            ListContentView(currnetSong: self.$currnetSong, libraryList:self.$libraryList)
            PlayerView(libraryList: self.$libraryList, currnetSong: self.$currnetSong)
            
//            ContentView1()
        }
                .frame(minWidth: 850, minHeight: 600 )
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environment(\.sizeCategory, .extraSmall)
//    }
//}





