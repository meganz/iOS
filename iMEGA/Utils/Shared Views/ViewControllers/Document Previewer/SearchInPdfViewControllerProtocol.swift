//
//  SearchInPdfViewControllerProtocol.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/19.
//  Copyright © 2023 MEGA. All rights reserved.
//

import Foundation

@objc protocol SearchInPdfViewControllerProtocol {
    @objc func didSelectSearchResult(_ result: PDFSelection)
}
