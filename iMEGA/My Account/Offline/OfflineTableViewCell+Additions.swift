import Foundation
import MEGADesignToken

private var AssociatedLoadThumbnailTaskHandle: UInt8 = 0

extension OfflineTableViewCell {
    open override func prepareForReuse() {
        super.prepareForReuse()
        loadThumbnailTask?.cancel()
    }
    
    private var loadThumbnailTask: Task<Void, any Error>? {
        get {
            objc_getAssociatedObject(self, &AssociatedLoadThumbnailTaskHandle) as? Task<Void, any Error>
        }
        set {
            objc_setAssociatedObject(self, &AssociatedLoadThumbnailTaskHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@objc extension OfflineTableViewCell {
    func setThumbnail(url: URL) {
        guard url.relativeString.fileExtensionGroup.isVisualMedia else { return }
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: url)
        loadThumbnailTask = Task { @MainActor [weak self] in
            guard let self, let image = await fileAttributeGenerator.requestThumbnail() else { return }
            try Task.checkCancellation()
            self.thumbnailImageView?.image = image
        }
    }
    
    func configureTokenColors() {
        infoLabel.textColor = TokenColors.Text.secondary
        nameLabel.textColor = TokenColors.Text.primary
        moreButton.tintColor = TokenColors.Icon.secondary
        backgroundColor = TokenColors.Background.page
    }
}
