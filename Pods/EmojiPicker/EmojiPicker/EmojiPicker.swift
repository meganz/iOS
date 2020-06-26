//
//  EmojiPicker.swift
//  EmojiPicker
//
//  Created by levantAJ on 12/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import UIKit

open class EmojiPicker {
    public class var viewController: EmojiPickerViewController {
        let storyboard = UIStoryboard(name: "EmojiPicker", bundle: Bundle(for: EmojiPickerViewController.self))
        let viewController = storyboard.instantiateInitialViewController() as! EmojiPickerViewController
        viewController.modalPresentationStyle = .overCurrentContext
        return viewController
    }
}

