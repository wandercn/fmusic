//
//  ModifiersView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/19.
//

import SwiftUI

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
                Rectangle()
            )
            .scaleEffect(isHovered ? 0.99 : 1.0)
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

struct ImageOnHover: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.5 : 1.0)
            .offset(x: isHovered ? 20 : 0, y: isHovered ? -50 : 0)
            .onHover { isHovered in
                withAnimation {
                    self.isHovered = isHovered
                }
            }
    }
}

extension View {
    func imageOnHover() -> some View {
        modifier(ImageOnHover())
    }
}

struct CircleImage: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 10)
    }
}

extension View {
    func circleImage() -> some View {
        modifier(CircleImage())
    }
}
