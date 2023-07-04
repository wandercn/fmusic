//
//  ContentView.swift
//  Shared
//
//  Created by lsmiao on 2023/6/16.
//

import SwiftUI

struct ContentView: View {
    //    @Binding var paths: [String]
    @State var currnetSong: Song = .init()
    @Binding var libraryList: [Song]
    var body: some View {
        VStack {
            Spacer()
            ListContentView(currnetSong: $currnetSong, libraryList: $libraryList)
            PlayerView(libraryList: $libraryList, currnetSong: $currnetSong)
        }
        .frame(minWidth: 850, minHeight: 600)
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//            .environment(\.sizeCategory, .extraSmall)
//    }
// }

struct BlueBackgroundOnHover: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.blue : Color.clear)
            .foregroundColor(isHovered ? Color.white : .secondary)
            .clipShape(
                Circle()
            )
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

struct PinkBackgroundOnHover: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.pink : Color.clear)
            .foregroundColor(isHovered ? Color.white : .secondary)
            .clipShape(
                Circle()
            )
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

extension View {
    func pinkBackgroundOnHover() -> some View {
        modifier(PinkBackgroundOnHover())
    }
}

struct ItemBackgroundOnHover: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.yellow : Color.clear)

            .clipShape(
                Capsule()
            )
            .scaleEffect(isHovered ? 0.97 : 1.0)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

extension View {
    func itemBackgroundOnHover() -> some View {
        modifier(ItemBackgroundOnHover())
    }
}
