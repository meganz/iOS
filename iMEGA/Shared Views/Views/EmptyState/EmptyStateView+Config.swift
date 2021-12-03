
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
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.allPhotosEmptyState.image,
                                  title: Strings.Localizable.Home.Images.empty,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func documentsEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.documentsEmptyState.image,
                                  title: Strings.Localizable.noDocumentsFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func audioEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.audioEmptyState.image,
                                  title: Strings.Localizable.noAudioFilesFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    class func videoEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.videoEmptyState.image,
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
