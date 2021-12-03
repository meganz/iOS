
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
                                  title: Strings.Localizable.Home.Images.empty,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func documentsEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "documentsEmptyState"),
                                  title: Strings.Localizable.noDocumentsFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func audioEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "audioEmptyState"),
                                  title: Strings.Localizable.noAudioFilesFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func videoEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: UIImage(named: "videoEmptyState"),
                                  title: Strings.Localizable.noVideosFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func favouritesEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.EmptyStates.favouritesEmptyState.image,
                                  title: Strings.Localizable.noFavourites,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
}
