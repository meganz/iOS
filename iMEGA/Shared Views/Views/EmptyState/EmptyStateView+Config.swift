
extension EmptyStateView {
    @objc class func create(for type: EmptyStateType,
                            image: UIImage? = nil,
                            title: String? = nil,
                            description: String? = nil,
                            buttonTitle: String? = nil) -> EmptyStateView {
        switch type {
        case .favourites:
            return favouritesEmptyState()
            
        case .photos:
            return photosEmptyState()
            
        case .timeline:
            return timelineEmptyState(image: image, title: title, description: description, buttonTitle: buttonTitle)
            
        case .documents:
            return documentsEmptyState()
            
        case .audio:
            return audioEmptyState()
            
        case .videos:
            return videoEmptyState()
            
        case .allMedia:
            return allMediaEmptyState()
        }
    }
    
    private class func photosEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.allPhotosEmptyState.image,
                                  title: Strings.Localizable.Home.Images.empty,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func allMediaEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.allPhotosEmptyState.image,
                                  title: Strings.Localizable.CameraUploads.Timeline.AllMedia.Empty.title,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func timelineEmptyState(image: UIImage?, title: String?, description: String?, buttonTitle: String?) -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: image,
                                  title: title,
                                  description: description,
                                  buttonTitle: buttonTitle)
        
        view.type = EmptyStateType.timeline.rawValue
        
        return view
    }
    
    private class func documentsEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.documentsEmptyState.image,
                                  title: Strings.Localizable.noDocumentsFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func audioEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.audioEmptyState.image,
                                  title: Strings.Localizable.noAudioFilesFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func videoEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.videoEmptyState.image,
                                  title: Strings.Localizable.noVideosFound,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func favouritesEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.EmptyStates.favouritesEmptyState.image,
                                  title: Strings.Localizable.noFavourites,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
}
