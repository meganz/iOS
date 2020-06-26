//
//  UIButto.swift
//  EmojiPicker
//
//  Created by levantAJ on 15/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import UIKit

extension UIButton {
    func setTitle(_ title: String?, for state: UIControl.State, animated: Bool = true) {
        if animated {
            setTitle(title, for: state)
        } else {
            UIView.performWithoutAnimation {
                setTitle(title, for: state)
                layoutIfNeeded()
            }
        }
    }
}
