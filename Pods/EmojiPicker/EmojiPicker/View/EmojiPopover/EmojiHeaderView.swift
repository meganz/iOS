//
//  EmojiHeaderView.swift
//  EmojiPicker
//
//  Created by levantAJ on 12/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import UIKit

final class EmojiHeaderView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
}

extension Constant {
    struct EmojiHeaderView {
        static let identifier = "EmojiHeaderView"
        static let height: CGFloat = 32
    }
}
