import Foundation
import MEGADesignToken
import MEGARepo

@MainActor private var AssociatedLoadThumbnailTaskHandle: UInt8 = 0

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

        if let cachedThumbnail = OfflineThumbnailCache.shared.image(for: url) {
            thumbnailImageView?.image = cachedThumbnail
            return
        }

        loadThumbnailTask?.cancel()
        loadThumbnailTask = Task { @MainActor [weak self] in
            guard let image = await OfflineThumbnailCache.shared.thumbnail(for: url) else { return }
            try Task.checkCancellation()
            self?.thumbnailImageView?.image = image
        }
    }
    
    func configureTokenColors() {
        infoLabel.textColor = TokenColors.Text.secondary
        nameLabel.textColor = TokenColors.Text.primary
        moreButton.tintColor = TokenColors.Icon.secondary
        backgroundColor = TokenColors.Background.page
    }
}
