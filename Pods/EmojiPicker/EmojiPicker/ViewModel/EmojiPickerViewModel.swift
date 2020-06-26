//
//  EmojiPickerViewModel.swift
//  EmojiPicker
//
//  Created by levantAJ on 12/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import Foundation

protocol EmojiPickerViewModelProtocol {
    var numberOfSections: Int { get }
    func numberOfEmojis(section: Int) -> Int
    func emoji(at indexPath: IndexPath) -> Emoji?
    func indexPath(of emoji: Emoji) -> IndexPath?
    func select(emoji: Emoji)
}

final class EmojiPickerViewModel {
    var emojis: [Int: [Emoji]] = [:]
    let userDefaults: UserDefaultsProtocol
    
    init(userDefaults: UserDefaultsProtocol) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: Constant.EmojiPickerViewModel.frequentlyUsed) {
            let frequentlyUsedEmojis = try! JSONDecoder().decode([Emoji].self, from: data)
            self.emojis[EmojiGroup.frequentlyUsed.index] = frequentlyUsedEmojis
        } else {
            self.emojis[EmojiGroup.frequentlyUsed.index] = []
        }
        let systemVersion = UIDevice.current.systemVersion
        let path: String
        if systemVersion.compare("10", options: .numeric) == .orderedAscending {
            path = Bundle(for: EmojiPickerViewModel.self).path(forResource: "emojis9.1", ofType: "json")!
        } else if systemVersion.compare("12", options: .numeric) == .orderedAscending {
            path = Bundle(for: EmojiPickerViewModel.self).path(forResource: "emojis11.0.1", ofType: "json")!
        } else {
            path = Bundle(for: EmojiPickerViewModel.self).path(forResource: "emojis", ofType: "json")!
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
        let categories = try! JSONDecoder().decode([Category].self, from: data)
        
        let selectedEmojis = userDefaults.dictionary(forKey: Constant.EmojiPickerViewModel.selectedEmojis) as? [String: String]
        for var category in categories {
            if let selectedEmojis = selectedEmojis {
                for (index, emoji) in category.emojis.enumerated() {
                    category.emojis[index].selectedEmoji = selectedEmojis[emoji.emojis.first!]
                }
            }
            self.emojis[category.type.index] = category.emojis
        }
    }
}

// MARK: - EmojiPickerViewModelProtocol

extension EmojiPickerViewModel: EmojiPickerViewModelProtocol {
    var numberOfSections: Int {
        return emojis.count
    }
    
    func numberOfEmojis(section: Int) -> Int {
        guard let type = EmojiGroup(index: section) else { return 0 }
        return emojis[type.index]?.count ?? 0
    }
    
    func emoji(at indexPath: IndexPath) -> Emoji? {
        guard let type = EmojiGroup(index: indexPath.section) else { return nil }
        return emojis[type.index]?[indexPath.item]
    }
    
    func select(emoji: Emoji) {
        updateFrequentlyUsed(emoji: emoji)
        updateSelectedEmoji(emoji)
        
        for item in emojis {
            guard item.key != EmojiGroup.frequentlyUsed.index,
                let index = item.value.firstIndex(where: { $0.emojis == emoji.emojis }) else { continue }
            emojis[item.key]?[index] = emoji
            break
        }
    }
    
    func indexPath(of emoji: Emoji) -> IndexPath? {
        for item in emojis {
            guard item.key != EmojiGroup.frequentlyUsed.index,
                let index = item.value.firstIndex(where: { $0.emojis == emoji.emojis }) else { continue }
            return IndexPath(item: index, section: item.key)
        }
        return nil
    }
}

// MARK: - Privates

extension EmojiPickerViewModel {
    private func updateFrequentlyUsed(emoji: Emoji) {
        var frequentlyUsedEmojis: [Emoji] = []
        if let data = userDefaults.data(forKey: Constant.EmojiPickerViewModel.frequentlyUsed) {
            frequentlyUsedEmojis = try! JSONDecoder().decode([Emoji].self, from: data)
        }
        if let index = frequentlyUsedEmojis.firstIndex(where: { $0.emojis == emoji.emojis }) {
            frequentlyUsedEmojis.remove(at: index)
        }
        frequentlyUsedEmojis = [emoji] + frequentlyUsedEmojis
        frequentlyUsedEmojis = Array(frequentlyUsedEmojis.prefix(upTo: min(frequentlyUsedEmojis.count, 30)))
        emojis[EmojiGroup.frequentlyUsed.index] = frequentlyUsedEmojis
        let data = try! JSONEncoder().encode(frequentlyUsedEmojis)
        userDefaults.set(data, forKey: Constant.EmojiPickerViewModel.frequentlyUsed)
    }
    
    private func updateSelectedEmoji(_ emoji: Emoji) {
        guard emoji.selectedEmoji != emoji.emojis.first else { return }
        var selectedEmojis = userDefaults.dictionary(forKey: Constant.EmojiPickerViewModel.selectedEmojis) as? [String: String] ?? [:]
        selectedEmojis[emoji.emojis.first!] = emoji.selectedEmoji
        userDefaults.set(selectedEmojis, forKey: Constant.EmojiPickerViewModel.selectedEmojis)
    }
}

struct Constant {
    struct EmojiPickerViewModel {
        static let frequentlyUsed = "com.levantAJ.EmojiPicker.frequentlyUsed"
        static let selectedEmojis = "com.levantAJ.EmojiPicker.selectedEmojis"
    }
}
