
extension EmptyStateView {
    class func create(for type: EmptyStateType) -> EmptyStateView {
        switch type {
        case .favourites:
            return favouritesEmptyState()
        
        case .photos:
            return photosEmptyState()
            
        case .documents:
            return documentsEmptyState()
            
        case .audio:
            return audioEmptyState()
            
        case .videos:
            return videoEmptyState()
        }
    }
    
    class func photosEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "allPhotosEmptyState"),
                                       title: NSLocalizedString("No images found", comment: "Photo Explorer Screen: No images in the account"),
                                       description: nil,
                                       buttonTitle: nil)
        
        return view
    }
    
    class func documentsEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "documentsEmptyState"),
                                       title: NSLocalizedString("No documents found", comment: "Photo Explorer Screen: No documents in the account"),
                                       description: nil,
                                       buttonTitle: nil)
        
        return view
    }
    
    class func audioEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "audioEmptyState"),
                                       title: NSLocalizedString("No audio files found", comment: "Audio Explorer Screen: No audio files in the account"),
                                       description: nil,
                                       buttonTitle: nil)
        
        return view
    }
    
    class func videoEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "videoEmptyState"),
                                       title: NSLocalizedString("No videos found", comment: "Video Explorer Screen: No audio files in the account"),
                                       description: nil,
                                       buttonTitle: nil)
        
        return view
    }
    
    class func favouritesEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "favouritesEmptyState"),
                                       title: NSLocalizedString("No Favourites", comment: "Text describing that there is not any node marked as favourite"),
                                       description: nil,
                                       buttonTitle: nil)
        
        return view
    }
}
