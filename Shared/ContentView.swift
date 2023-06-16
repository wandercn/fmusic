//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack{
            Spacer()
            ListContentView()
            PlayerView()
            
        }
        .frame(minWidth: 850, minHeight: 600 )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.sizeCategory, .extraSmall)
    }
}





struct SearchView: View {
    @Binding var  searched :Bool
    @State var  searchText = ""
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
    @Binding var libraryed: Bool
    var body: some View {
        List{
            HStack{
                Text("歌曲名")
                    .padding(.trailing,100)
                Text("艺术家")
                    .padding(.trailing,100)
                Text("专辑名")
                    .padding(.trailing,100)
                Text("时长")
                    .padding(.trailing,100)
            }
            ScrollView{
                
            }
        }
    }
    
}

