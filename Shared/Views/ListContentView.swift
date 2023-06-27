//
//  ListContentView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI
struct ListContentView: View {
    @Binding var currnetSong: Song
    @State private var libraryed = false
    @State private var playListed = false
    @State var searchText = ""
    @Binding var libraryList: [Song]
    var body: some View {
        NavigationView{
            List {
                Section(header:
                            HStack{
                    
                    Text("资料库")
                    Image(systemName: "flame.fill")
                }
                    .font(.headline)
                    .foregroundColor(.red)
                ){
                    NavigationLink("歌曲",isActive: self.$libraryed){
                        LibraryView(currnetSong: self.$currnetSong, libraryed: self.$libraryed,libraryList:self.$libraryList,searchText: self.$searchText)
                    }.padding(.leading, 10)
                }
                .headerProminence(.increased)

                Section(header: HStack{
                    Text("播放列表")
                    Image(systemName: "music.note.list")
                }
                    .font(.headline)
                    .foregroundColor(.orange)
                ) {
                    NavigationLink("所有播放列表",isActive: self.$playListed){
                        List{
                            Text("播放列表1")
                            Text("播放列表2")
                        }
                        

                    }.padding(.leading, 10)
                    NavigationLink("播放列表1"){
                        Text("歌曲1")
                        Text("歌曲1")
                    }.padding(.leading, 10)
                    
                }.headerProminence(.increased)
                
                Section(header: HStack{
                    Text("我的收藏")
                    Image(systemName: "suit.heart")
                }
                    .font(.headline)
                    .foregroundColor(.purple)
                ) {
                    NavigationLink("我的收藏"){
                        
                    }.padding(.leading, 10)
                }.headerProminence(.increased)
                Spacer()
            }
            .searchable(text: self.$searchText,placement: .sidebar,prompt: "搜索")
            .navigationTitle("music")
            // 侧边搜索栏
           
        }
        .navigationViewStyle(.columns)
        
    }
}


struct SearchView: View {
    @Binding var  searched :Bool
    @Binding var  searchText : String
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment:.trailing) {
                    TextField("请输入搜索内容", text:self.$searchText )
                        .frame(width: 300)
                    Button {
                        
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    
                }
                Spacer()
                
            }
            Spacer()
        }
    }
}

struct LibraryView: View {
    @Binding var currnetSong: Song
    @Binding var libraryed: Bool
    @Binding var libraryList: [Song]
    @Binding var searchText: String
    
    //    var searchResults:[Song] = []
    // 列表显示搜索结果
    var searchResults: [Song] {
        if searchText.isEmpty{
            return self.libraryList
        }else{
            return self.libraryList.filter { x in
                x.name.contains(searchText) || x.album.contains(searchText) ||
                x.artist.contains(searchText)
            }
        }
    }
    var body: some View {
        
        HStack{
            Text("歌曲名")
                .font(.headline) // 字C体
                .fontWeight(.semibold) // 字体粗细
                .foregroundColor(.white)// 前景颜色
                .frame(width:185,alignment: .leading)
                .padding(.horizontal,15)
            
            Text("艺术家")
                .font(.headline) // 字体
                .fontWeight(.semibold) // 字体粗细
                .foregroundColor(.white)// 前景颜色
                .frame(width:150,alignment: .leading)
            
            Text("专辑名")
                .font(.headline) // 字体
                .fontWeight(.semibold) // 字体粗细
                .foregroundColor(.white)// 前景颜色
                .frame(width:150,alignment: .leading)
            
            Text("时长")
                .font(.headline) // 字体
                .fontWeight(.semibold) // 字体粗细
                .foregroundColor(.white)// 前景颜色
                .frame(width:150,alignment: .leading)
            
            Spacer()
        }
        .background(
            Color.gray
            
                .cornerRadius(5)
           
            
        )
        List {
            ForEach(searchResults,id: \.self) {song in
                RowView(libraryList: self.$libraryList, currnetSong: self.$currnetSong, song:song)
                    
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
    //    func deleteItem(offsets: IndexSet){
    //        libraryList.remove(atOffsets: offsets)
    //    }
    
}


struct RowView: View{
    @Binding var libraryList: [Song]
    @Binding var currnetSong: Song
    @State var song: Song
//    @State var isClicked: Bool = false
    var body: some View {
        Button {
//            print(song.name)
            self.currnetSong = song
            song.isSelected.toggle()
            if self.$libraryList.count > 0{
                for index in 0..<self.$libraryList.count {
                    if self.libraryList[index].filePath == self.currnetSong.filePath{
                        self.libraryList[index].isSelected = true
                    }
                }
//                print(self.$libraryList)
            }
        } label: {
            HStack{
                Text(song.name)
                    .font(.headline) // 字体
                    .fontWeight(.semibold) // 字体粗细
                    .frame(width:200,alignment: .leading)
                Text(song.artist)
                    .font(.headline) // 字体
                    .fontWeight(.semibold) // 字体粗细
                    .frame(width:150,alignment: .leading)
                Text(song.album)
                    .font(.headline) // 字体
                    .fontWeight(.semibold) // 字体粗细
                    .frame(width:150,alignment: .leading)
                Text(durationFormat(timeInterval: song.duration))
                    .font(.headline) // 字体
                    .fontWeight(.semibold) // 字体粗细
                    .frame(width:150,alignment: .leading)
                Spacer()
            }
            .foregroundColor(song.isSelected ? Color.white: Color.secondary)//前景颜色
            
        
            
        }
        .buttonStyle(.borderless)
        .background(song.isSelected ? Color.purple : Color.clear)
        .itemBackgroundOnHover()
    }
}


// 双击按钮
struct DoubleTapButtonStyle: PrimitiveButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .gesture(TapGesture(count: 2).onEnded { configuration.trigger() })
  }
}
