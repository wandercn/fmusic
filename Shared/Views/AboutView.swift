//
//  AboutView.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/8/23.
//
import Foundation
import SwiftUI

struct AboutView: View {
    private var github: String = "https://github.com/wandercn/fmusic"
    private var email: String = "wander@ffactory.org"
    private var website: URL { URL(string: github)! }
    private var authorEmail: URL { URL(string: "mailto:\(email)")! }
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            HStack { Image(nsImage: NSImage(named: "AppIcon")!)
                .resizable()
                .scaledToFit()
            }
            .frame(width: 64, height: 64)

            Text("\(Bundle.main.appName)")
                .font(.largeTitle)
                .foregroundColor(.black)
                .bold()
            Text("Version \(Bundle.main.appVersionLong)")
            VStack(alignment: .leading, spacing: 5) {
                Text("fmusic is a open source music player.")
                Text("基于SwiftUI开发的本地音乐播放器")
                HStack {
                    Text("GitHub:")
                    Link(github.replacingOccurrences(of: "https://", with: ""), destination: website)
                }
                HStack {
                    Text("Email:")
                    Link(email, destination: authorEmail)
                }
            }
            Text(Bundle.main.copyright)
                .font(.body)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(10)
        .frame(minWidth: 400, minHeight: 300)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
