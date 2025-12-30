import MEGAAssets
import MEGADesignToken
import MEGADomain

extension NodeCollectionViewCell {
    static private var folderLinkNibName = "FolderLinkNodeCollectionViewCell"

    static let folderLinkReusableIdentifier = "FolderLinkNodeCollectionViewCellID"

    static var folderLinkCellNib: UINib {
        UINib(nibName: folderLinkNibName, bundle: nil)
    }

    class var instantiateFolderLinkCellFromNib: Self {
        guard let cell = Bundle(for: Self.self)
            .loadNibNamed(folderLinkNibName, owner: nil, options: nil)?.first as? Self else {
                fatalError("could not load the instance from nib")
        }

        return cell
    }

    @objc func configureCellForFolderLinkNode(
        _ node: MEGANode,
        allowedMultipleSelection: Bool,
        sdk: MEGASdk,
        delegate: (any NodeCollectionViewCellDelegate)?,
        usesRevampedUI: Bool
    ) {
        configureCell(
            for: node,
            allowedMultipleSelection: allowedMultipleSelection,
            isFromSharedItem: true,
            sdk: sdk,
            delegate: delegate
        )
        
        downloadedImageView?.isHidden = !hasDownloaded(node: node)
        
        guard usesRevampedUI else { return }
        nameLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        
        let labelPath = node.toNodeEntity().label.labelString
        labelImageView?.image = MEGAAssets.UIImage.image(named: "\(labelPath)Small")
        
        topNodeIconsView?.backgroundColor = .clear
        
        downloadedImageView?.image = MEGAAssets.UIImage.arrowDownCircle
        
        favouriteView?.backgroundColor = TokenColors.Background.surfaceTransparent
        favouriteView?.layer.cornerRadius = TokenRadius.small
        favouriteImageView?.image = MEGAAssets.UIImage.heart
        favouriteImageView?.tintColor = TokenColors.Icon.onColor
        favouriteImageView?.contentMode = .scaleAspectFit
        
        durationLabel?.textColor = TokenColors.Text.onColor
        durationLabel?.backgroundColor = .clear
        let durationParentView = durationLabel?.superview
        durationParentView?.isHidden = durationLabel?.isHidden == true
        durationParentView?.backgroundColor = TokenColors.Background.surfaceTransparent
        durationParentView?.layer.cornerRadius = TokenRadius.small
        
        // Note: The sizing logic for the image of `moreButton` is done in the xib using `Image insets`.
        moreButton?.setImage(MEGAAssets.UIImage.moreHorizontal, for: .normal)
        moreButton?.imageView?.contentMode = .scaleAspectFit
        moreButton?.imageView?.tintColor = TokenColors.Icon.primary
        
        contentView.layer.borderColor = UIColor.clear.cgColor
    }
}
