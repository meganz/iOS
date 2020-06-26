//
//  EmojiPickerContentViewController.swift
//  EmojiPicker
//
//  Created by levantAJ on 12/11/18.
//  Copyright © 2018 levantAJ. All rights reserved.
//

import UIKit

protocol EmojiPopoverViewControllerDelegate: class {
    func emojiPickerViewControllerDidDimiss(_ controller: EmojiPopoverViewController)
    func emojiPickerViewController(_ controller: EmojiPopoverViewController, brief emoji: Emoji, sourceView: UIView)
    func emojiPickerViewController(_ controller: EmojiPopoverViewController, preview emoji: Emoji, sourceView: UIView)
    func emojiPickerViewController(_ controller: EmojiPopoverViewController, didSelect emoji: Emoji)
    func emojiPickerViewControllerHideDeselectEmoji(_ controller: EmojiPopoverViewController)
}

final class EmojiPopoverViewController: UIViewController {
    var sourceRect: CGRect = .zero {
        didSet {
            popoverPresentationController?.sourceRect = sourceRect
        }
    }
    var sourceView: UIView? {
        didSet {
            popoverPresentationController?.sourceView = sourceView
        }
    }
    var permittedArrowDirections: UIPopoverArrowDirection = .any {
        didSet {
            popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        }
    }
    var emojiFontSize: CGFloat = 29 {
        didSet {
            emojisCollectionView?.reloadData()
        }
    }
    var backgroundColor: UIColor? = UIColor.white.withAlphaComponent(0.5) {
        didSet {
            changeDarkModeStyle()
        }
    }
    var darkModeBackgroundColor: UIColor? = UIColor.black.withAlphaComponent(0.5) {
        didSet {
            changeDarkModeStyle()
        }
    }
    var isDarkMode = false {
        didSet {
            changeDarkModeStyle()
        }
    }
    var language: String? {
        didSet {
            UserDefaults.standard.set(language, forKey: Constant.CurrentLanguage.currentLanguageKey)
        }
    }
    var dismissAfterSelected = false
    weak var delegate: EmojiPopoverViewControllerDelegate?
    
    @IBOutlet weak var emojisCollectionView: UICollectionView!
    @IBOutlet weak var groupsCollectionView: UICollectionView!
    @IBOutlet weak var bottomVisualEffectView: UIVisualEffectView!
    @IBOutlet weak var groupTopLineView: UIView!
    var selectedGroupCell: GroupCollectionViewCell?
    lazy var viewModel: EmojiPickerViewModelProtocol = EmojiPickerViewModel(userDefaults: UserDefaults.standard)
    lazy var vibrator: Vibratable = Vibrator()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        modalPresentationStyle = .popover
        popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        popoverPresentationController?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func select(emoji: Emoji) {
        viewModel.select(emoji: emoji)
        emojisCollectionView.reloadSections(IndexSet(integer: EmojiGroup.frequentlyUsed.index))
        guard let indexPath = viewModel.indexPath(of: emoji) else { return }
        emojisCollectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDataSource

extension EmojiPopoverViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        delegate?.emojiPickerViewControllerDidDimiss(self)
    }
}

// MARK: - UICollectionViewDataSource

extension EmojiPopoverViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == emojisCollectionView {
            return viewModel.numberOfSections
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojisCollectionView {
            return viewModel.numberOfEmojis(section: section)
        }
        return viewModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojisCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.EmojiCollectionViewCell.identifier, for: indexPath) as! EmojiCollectionViewCell
            cell.delegate = self
            cell.emojiFontSize = emojiFontSize
            if let emoji = viewModel.emoji(at: indexPath) {
                cell.emoji = emoji
            }
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constant.GroupCollectionViewCell.identifier, for: indexPath) as! GroupCollectionViewCell
        cell.indexPath = indexPath
        cell.delegate = self
        cell.isDarkMode = isDarkMode
        if let group = EmojiGroup(index: indexPath.item) {
            cell.image = UIImage(named: group.rawValue, in: Bundle(for: GroupCollectionViewCell.self), compatibleWith: nil)
        }
        if selectedGroupCell == nil {
            selectedGroupCell = cell
            selectedGroupCell?.isSelected = true
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

extension EmojiPopoverViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == emojisCollectionView {
            return Constant.EmojiCollectionViewCell.size
        }
        return CGSize(width: max(collectionView.frame.width/CGFloat(viewModel.numberOfSections), 32), height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == emojisCollectionView {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constant.EmojiHeaderView.identifier, for: indexPath) as! EmojiHeaderView
            if let group = EmojiGroup(index: indexPath.section) {
                headerView.title = group.name
            }
            return headerView
        }
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constant.GroupHeaderView.identifier, for: indexPath)
        return headerView
    }
}

// MARK: - UIScrollViewDelegate

extension EmojiPopoverViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        selectCurrentGroupCell()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        selectCurrentGroupCell()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.emojiPickerViewControllerHideDeselectEmoji(self)
    }
}

// MARK: - GroupCollectionViewCellDelegate

extension EmojiPopoverViewController: EmojiCollectionViewCellDelegate {
    func emojiCollectionViewCell(_ cell: EmojiCollectionViewCell, brief emoji: Emoji) {
        delegate?.emojiPickerViewController(self, brief: emoji, sourceView: cell)
    }
    
    func emojiCollectionViewCell(_ cell: EmojiCollectionViewCell, select emoji: Emoji) {
        delegate?.emojiPickerViewController(self, didSelect: emoji)
        viewModel.select(emoji: emoji)
        if dismissAfterSelected {
            dismiss(animated: true) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.emojiPickerViewControllerDidDimiss(strongSelf)
            }
        } else if viewModel.indexPath(of: emoji) != nil {
            emojisCollectionView.reloadSections(IndexSet(integer: EmojiGroup.frequentlyUsed.index))
        }
    }
    
    func emojiCollectionViewCell(_ cell: EmojiCollectionViewCell, deselect emoji: Emoji) {
        delegate?.emojiPickerViewControllerHideDeselectEmoji(self)
    }
    
    func emojiCollectionViewCell(_ cell: EmojiCollectionViewCell, preview emoji: Emoji) {
        delegate?.emojiPickerViewController(self, preview: emoji, sourceView: cell)
    }
}

// MARK: - GroupCollectionViewCellDelegate

extension EmojiPopoverViewController: GroupCollectionViewCellDelegate {
    func groupCollectionViewCell(_ cell: GroupCollectionViewCell, didSelect indexPath: IndexPath) {
        selectedGroupCell?.isSelected = false
        selectedGroupCell = cell
        selectedGroupCell?.isSelected = true
        if indexPath.item == 0 {
            emojisCollectionView.scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)), animated: true)
        } else if let attributes = emojisCollectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: indexPath.item)) {
            emojisCollectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - emojisCollectionView.contentInset.top), animated: true)
        }
    }
}

// MARK: - Privates

extension EmojiPopoverViewController {
    private func setupViews() {
        emojisCollectionView.delegate = self
        emojisCollectionView.dataSource = self
        groupsCollectionView.delegate = self
        groupsCollectionView.dataSource = self
        
        var nib = UINib(nibName: Constant.EmojiCollectionViewCell.identifier, bundle: Bundle(for: EmojiCollectionViewCell.self))
        emojisCollectionView.register(nib, forCellWithReuseIdentifier: Constant.EmojiCollectionViewCell.identifier)
        nib = UINib(nibName: Constant.EmojiHeaderView.identifier, bundle: Bundle(for: EmojiHeaderView.self))
        emojisCollectionView.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constant.EmojiHeaderView.identifier)
        var layout = emojisCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.headerReferenceSize = CGSize(width: emojisCollectionView.frame.width, height: Constant.EmojiHeaderView.height)
        
        nib = UINib(nibName: Constant.GroupCollectionViewCell.identifier, bundle: Bundle(for: GroupCollectionViewCell.self))
        groupsCollectionView.register(nib, forCellWithReuseIdentifier: Constant.GroupCollectionViewCell.identifier)
        nib = UINib(nibName: Constant.GroupHeaderView.identifier, bundle: Bundle(for: GroupHeaderView.self))
        groupsCollectionView.register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Constant.GroupHeaderView.identifier)
        layout = groupsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout?.headerReferenceSize = CGSize(width: 0, height: 0)
        
        changeDarkModeStyle()
    }
    
    private func changeDarkModeStyle() {
        popoverPresentationController?.backgroundColor = isDarkMode ? darkModeBackgroundColor : backgroundColor
        bottomVisualEffectView?.effect = UIBlurEffect(style: isDarkMode ? .dark : .light)
        groupTopLineView?.backgroundColor = UIColor(hexString: isDarkMode ? "#3d3d3d" : "#9d9d9d")?.withAlphaComponent(0.3)
    }
    
    private func selectCurrentGroupCell() {
        guard let emojiCell = emojisCollectionView.visibleCells.first,
            let indexPath = emojisCollectionView.indexPath(for: emojiCell),
            let groupCell = groupsCollectionView.cellForItem(at: IndexPath(item: indexPath.section, section: 0)) as? GroupCollectionViewCell else { return }
        selectedGroupCell?.isSelected = false
        selectedGroupCell = groupCell
        selectedGroupCell?.isSelected = true
    }
}
