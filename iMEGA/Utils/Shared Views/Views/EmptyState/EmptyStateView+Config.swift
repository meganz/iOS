
extension EmptyStateView {
    static func create(for type: EmptyStateType) -> EmptyStateView {
        switch type {
        case .favourites:
            return favouritesEmptyState()
            
        case .photos:
            return photosEmptyState()
            
        case .timeline(let image, let title, let description, let buttonTitle):
            return timelineEmptyState(image: image, title: title, description: description, buttonTitle: buttonTitle)
            
        case .documents:
            return documentsEmptyState()
            
        case .audio:
            return audioEmptyState()
            
        case .videos:
            return videoEmptyState()
            
        case .backups(let searchActive):
            return backupsEmptyState(searchActive: searchActive)
            
        case .allMedia:
            return allMediaEmptyState()
        }
    }
    
    private class func photosEmptyState() -> EmptyStateView {
        EmptyStateView(forHomeWith: Asset.Images.Home.allPhotosEmptyState.image,
                       title: Strings.Localizable.Home.Images.empty,
                       description: nil,
                       buttonTitle: nil)
    }
    
    private class func allMediaEmptyState() -> EmptyStateView {
        let view = EmptyStateView(forHomeWith: Asset.Images.Home.allPhotosEmptyState.image,
                                  title: Strings.Localizable.CameraUploads.Timeline.AllMedia.Empty.title,
                                  description: nil,
                                  buttonTitle: nil)
        
        return view
    }
    
    private class func timelineEmptyState(image: UIImage?, title: String?, description: String?, buttonTitle: String?) -> EmptyStateView {
        EmptyStateView(forTimelineWith: image,
                       title: title,
                       description: description,
                       buttonTitle: buttonTitle)
    }
    
    private class func documentsEmptyState() -> EmptyStateView {
        EmptyStateView(forHomeWith: Asset.Images.Home.documentsEmptyState.image,
                       title: Strings.Localizable.noDocumentsFound,
                       description: nil,
                       buttonTitle: nil)
    }
    
    private class func audioEmptyState() -> EmptyStateView {
        EmptyStateView(forHomeWith: Asset.Images.Home.audioEmptyState.image,
                       title: Strings.Localizable.noAudioFilesFound,
                       description: nil,
                       buttonTitle: nil)
    }
    
    private class func videoEmptyState() -> EmptyStateView {
        EmptyStateView(forHomeWith: Asset.Images.Home.videoEmptyState.image,
                       title: Strings.Localizable.noVideosFound,
                       description: nil,
                       buttonTitle: nil)
    }
    
    private class func favouritesEmptyState() -> EmptyStateView {
        EmptyStateView(forHomeWith: Asset.Images.EmptyStates.favouritesEmptyState.image,
                       title: Strings.Localizable.noFavourites,
                       description: nil,
                       buttonTitle: nil)
    }
    
    private class func backupsEmptyState(searchActive: Bool) -> EmptyStateView {
        EmptyStateView(forHomeWith: searchActive ? Asset.Images.EmptyStates.searchEmptyState.image : Asset.Images.EmptyStates.folderEmptyState.image,
                       title: searchActive ? Strings.Localizable.noResults : Strings.Localizable.Backups.Empty.State.message,
                       description: searchActive ? nil : Strings.Localizable.Backups.Empty.State.description,
                       buttonTitle: nil)
    }
}
