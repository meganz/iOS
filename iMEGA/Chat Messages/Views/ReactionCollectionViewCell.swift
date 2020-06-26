//
//  ReactionCollectionViewCell.swift
//  MEGA
//
//  Created by Haoran Li on 26/06/20.
//  Copyright © 2020 MEGA. All rights reserved.
//

import UIKit

class ReactionCollectionViewCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        // Initialization code
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
       
        let size = self.contentView.systemLayoutSizeFitting(layoutAttributes.size)
        var cellFrame = layoutAttributes.frame
        cellFrame.size = size
        layoutAttributes.frame = cellFrame
        return layoutAttributes
    }
}
