//
//  ListContentView.swift
//  music
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI
struct ListContentView: View {
    @State var  searched = true
    @State var libraryed = true
    var body: some View {
        NavigationView{
            List {
                
                NavigationLink("搜索", isActive: self.$searched) {
                    SearchView(searched: self.$searched)
                }
                
                NavigationLink("音乐库",isActive: self.$libraryed){
                    LibraryView(libraryed: self.$libraryed)
                }
                
            }.navigationViewStyle(.columns)
            
        }
    }
}
