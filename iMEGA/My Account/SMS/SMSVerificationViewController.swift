//
//  SMSVerificationViewController.swift
//  MEGA
//
//  Created by Simon Wang on 8/05/19.
//  Copyright © 2019 MEGA. All rights reserved.
//

import UIKit

class SMSVerificationViewController: UIViewController {
    
    @IBOutlet private var scrollView: UIScrollView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.isHidden = true

        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}
