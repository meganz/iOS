//
//  PDFOutlineView.swift
//  MEGA
//
//  Created by Meler Paine on 2023/3/14.
//  Copyright © 2023 MEGA. All rights reserved.
//

import Foundation
import UIKit

@objc class PDFOutlineView: UIView, UITableViewDataSource, UITableViewDelegate {
    var tableView: UITableView
    @objc var outline: [PDFOutlineItem]
    @objc var selectOutlineItemHandler: ((PDFOutlineItem) -> Void)?
    
    @objc
    init(outline: [PDFOutlineItem]) {
        self.outline = outline
        tableView = UITableView(frame: .zero, style: .plain)
        super.init(frame: .zero)
        configView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func reload() {
        tableView.reloadData()
    }
    
    private func configView() {
        self.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        tableView.register(PDFOutlineItemCell.self, forCellReuseIdentifier: "PDFOutlineItemCell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func updateAppearance() {
        backgroundColor = .mnz_backgroundElevated(traitCollection)
        tableView.backgroundColor = .mnz_backgroundElevated(traitCollection)
        tableView.separatorColor = .mnz_separator(for: traitCollection)
        
        tableView.reloadData()
    }
    
    //MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let outlineItem = outline[indexPath.row]
        if selectOutlineItemHandler != nil {
            selectOutlineItemHandler!(outlineItem)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return outline.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let outlineItem = outline[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PDFOutlineItemCell", for: indexPath) as! PDFOutlineItemCell
        cell.titleLabel.text = outlineItem.label
        cell.pageNumberLabel.text = String(outlineItem.pageNumber)
        cell.indentLevel = outlineItem.level
        return cell
    }
}

@objc
class PDFOutlineItemCell: UITableViewCell {

    let titleLabel = UILabel()
    let pageNumberLabel = UILabel()
    var indentLevel = 0
    var widthConstraint: NSLayoutConstraint?
    var indentationConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(pageNumberLabel)
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func layout() {
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        indentationConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15)
        indentationConstraint?.isActive = true
        
        titleLabel.lineBreakMode = .byWordWrapping
        let leadingConstraint = titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: pageNumberLabel.leadingAnchor, constant: -20)
        leadingConstraint.priority = UILayoutPriority(rawValue: 998)
        leadingConstraint.isActive = true
        
        pageNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        pageNumberLabel.font = UIFont.systemFont(ofSize: 16, weight: .light)
        widthConstraint = pageNumberLabel.widthAnchor.constraint(equalToConstant: 10)
        widthConstraint?.isActive = true
        pageNumberLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        pageNumberLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        
        let trailingConstraint = pageNumberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        trailingConstraint.priority = UILayoutPriority(rawValue: 1000)
        trailingConstraint.isActive = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if pageNumberLabel.text != nil {
            widthConstraint?.constant = pageNumberLabel.intrinsicContentSize.width
        }
        indentationConstraint!.constant = CGFloat(15 + indentLevel * 15)
        setNeedsUpdateConstraints()
    }
}

@objc class PDFOutlineItem: NSObject {
    @objc var level: Int = 0
    @objc var label: String
    @objc var pageNumber: Int
    
    init(level: Int = 0, label: String, pageNumber: Int) {
        self.level = level
        self.label = label
        self.pageNumber = pageNumber
    }
    
    @objc static func getOutline(_ document: PDFDocument) -> [PDFOutlineItem] {
        guard let outlineRoot = document.outlineRoot else { return [] }
        var items = [PDFOutlineItem]()
        var outlineStack: [(level: Int, outline: PDFOutline)] = getChildOutline(outlineRoot).map({ (0, $0)}).reversed()
        
        while outlineStack.count > 0 {
            let lastItem = outlineStack.removeLast()
            var pageNumber = 1
            let page = lastItem.outline.destination?.page
            if page == nil {
                pageNumber = 1
            } else {
                pageNumber = document.index(for: page!) + 1
            }
            items.append(PDFOutlineItem(level: lastItem.level, label: lastItem.outline.label ?? "", pageNumber: pageNumber))
            
            let childCount = lastItem.outline.numberOfChildren
            var children = [(level: Int, outline: PDFOutline)]()
            for index in 0..<childCount {
                if let child = lastItem.outline.child(at: index) {
                    children.append((level: lastItem.level + 1, outline: child))
                }
            }
            outlineStack.append(contentsOf: children.reversed())
        }
        
        return items
    }
    
    private static func getChildOutline(_ outline: PDFOutline) -> [PDFOutline] {
        var children = [PDFOutline]()
        for index in 0..<outline.numberOfChildren {
            if let child = outline.child(at: index) {
                children.append(child)
            }
        }
        return children
    }
    
}
