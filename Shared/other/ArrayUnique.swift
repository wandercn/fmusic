//
//  ArrayUnique.swift
//  fmusic (macOS)
//
//  Created by lsmiao on 2023/7/21.
//

import Foundation

/// 数组去重 Array unique
extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}
