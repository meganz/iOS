//
//  Category.swift
//  EmojiPicker
//
//  Created by levantAJ on 12/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import Foundation

enum EmojiGroup: String, Codable {
    case frequentlyUsed
    case smileysAndPeople
    case animalsAndNature
    case foodAndDrink
    case activity
    case travelAndPlaces
    case objects
    case symbols
    case flags
    
    init?(index: Int) {
        switch index {
        case 0:
            self = .frequentlyUsed
        case 1:
            self = .smileysAndPeople
        case 2:
            self = .animalsAndNature
        case 3:
            self = .foodAndDrink
        case 4:
            self = .activity
        case 5:
            self = .travelAndPlaces
        case 6:
            self = .objects
        case 7:
            self = .symbols
        case 8:
            self = .flags
        default:
            return nil
        }
    }
    
    var index: Int {
        switch self {
        case .frequentlyUsed:
            return 0
        case .smileysAndPeople:
            return 1
        case .animalsAndNature:
            return 2
        case .foodAndDrink:
            return 3
        case .activity:
            return 4
        case .travelAndPlaces:
            return 5
        case .objects:
            return 6
        case .symbols:
            return 7
        case .flags:
            return 8
        }
    }
    
    var name: String {
        switch self {
        case .frequentlyUsed:
            return "FREQUENTLY USED".localized
        case .smileysAndPeople:
            return "SMILEYS & PEOPLE".localized
        case .animalsAndNature:
            return "ANIMALS & NATURE".localized
        case .foodAndDrink:
            return "FOOD & DRINK".localized
        case .activity:
            return "ACTIVITY".localized
        case .travelAndPlaces:
            return "TRAVEL AND PLACES".localized
        case .objects:
            return "OBJECTS".localized
        case .symbols:
            return "SYMBOLS".localized
        case .flags:
            return "FLAGS".localized
        }
    }
}

struct Category: Codable {
    var emojis: [Emoji]!
    var type: EmojiGroup!
    
    enum CodingKeys: String, CodingKey {
        case emojis
        case type
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        emojis = try values.decode([[String]].self, forKey: .emojis).map { Emoji(emojis: $0) }
        type = try values.decode(EmojiGroup.self, forKey: .type)
    }
}
