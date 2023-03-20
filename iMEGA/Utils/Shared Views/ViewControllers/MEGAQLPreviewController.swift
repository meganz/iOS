//
//  MEGAQLPreviewController.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/19.
//  Copyright © 2023 MEGA. All rights reserved.
//

import QuickLook

class MEGAQLPreviewController: QLPreviewController, UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    private var filePath: String
    private var files: [String]
    
    
    @objc init(filePath: String) {
        self.filePath = filePath
        self.files = []
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        self.dataSource = self
        self.title = (filePath as NSString).lastPathComponent
        self.transitioningDelegate = self
    }
    
    @objc init(arrayOfFiles files: [String]) {
        self.filePath = ""
        self.files = files
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        self.dataSource = self
        self.transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        if !self.files.isEmpty {
            return self.files.count
        } else {
            return 1
        }
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if !self.files.isEmpty {
            self.filePath = self.files[index]
        }
        return NSURL(fileURLWithPath:self.filePath)
    }
    
    // MARK: - QLPreviewControllerDelegate
    
    func previewController(
        _ controller: QLPreviewController,
        shouldOpen url: URL,
        for item: QLPreviewItem
    ) -> Bool {
        DispatchQueue.main.async {
            MEGALinkManager.linkURL = url
            MEGALinkManager.processLinkURL(url)
        }
        
        return false
    }
    
}

