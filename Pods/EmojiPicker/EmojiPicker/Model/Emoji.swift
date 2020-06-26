//
//  Emoji.swift
//  EmojiPicker
//
//  Created by levantAJ on 16/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import Foundation

struct Emoji: Codable {
    var emojis: [String]!
    var selectedEmoji: String?
    
    init(emojis: [String], selectedEmoji: String? = nil) {
        self.emojis = emojis
        self.selectedEmoji = selectedEmoji
    }
}
