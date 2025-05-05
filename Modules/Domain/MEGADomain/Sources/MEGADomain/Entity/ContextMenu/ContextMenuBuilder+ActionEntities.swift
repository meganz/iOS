extension ContextMenuBuilder {
    
    // MARK: - Upload Add Actions
    
    var choosePhotoVideo: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .chooseFromPhotos))
    }
    
    var capturePhotoVideo: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .capture))
    }
    
    var importFromFiles: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .importFrom))
    }
    
    var importFolderLink: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .importFolderLink))
    }
    
    var newTextFile: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .newTextFile))
    }
    
    var scanDocument: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .scanDocument))
    }
    
    var newFolder: CMActionEntity {
        CMActionEntity(type: .uploadAdd(actionType: .newFolder))
    }
    
    // MARK: - Display Actions
    
    var select: CMActionEntity {
        CMActionEntity(type: .display(actionType: .select))
    }
    
    var thumbnailView: CMActionEntity {
        CMActionEntity(type: .display(actionType: .thumbnailView),
                       state: currentViewMode() == .thumbnail ? .on : .off)
    }
    
    var listView: CMActionEntity {
        CMActionEntity(type: .display(actionType: .listView),
                       state: currentViewMode() == .list ? .on : .off)
    }
    
    var emptyRubbishBin: CMActionEntity {
        CMActionEntity(type: .display(actionType: .clearRubbishBin))
    }
    
    var newPlaylist: CMActionEntity {
        CMActionEntity(type: .display(actionType: .newPlaylist))
    }
    
    var mediaDiscovery: CMActionEntity {
        CMActionEntity(
            type: .display(actionType: .mediaDiscovery),
            state: currentViewMode() == .mediaDiscovery ? .on : .off)
    }
    
    // MARK: - Sort Actions
    
    var sortNameAscending: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .defaultAsc),
                       state: currentSortType() == .defaultAsc ? .on : .off)
    }
    
    var sortNameDescending: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .defaultDesc),
                       state: currentSortType() == .defaultDesc ? .on : .off)
    }
    
    var sortLargest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .sizeDesc),
                       state: currentSortType() == .sizeDesc ? .on : .off)
    }
    
    var sortSmallest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .sizeAsc),
                       state: currentSortType() == .sizeAsc ? .on : .off)
    }
    
    var sortNewest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .modificationDesc),
                       state: currentSortType() == .modificationDesc ? .on : .off)
    }
    
    var sortOldest: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .modificationAsc),
                       state: currentSortType() == .modificationAsc ? .on : .off)
    }
    
    var sortLabel: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .labelAsc),
                       state: currentSortType() == .labelAsc ? .on : .off)
    }
    
    var sortFavourite: CMActionEntity {
        CMActionEntity(type: .sort(actionType: .favouriteAsc),
                       state: currentSortType() == .favouriteAsc ? .on : .off)
    }
    
    // MARK: - Filter Actions
    func filter(isActive: Bool) -> CMActionEntity {
        CMActionEntity(type: .display(actionType: isActive ? .filterActive : .filter))
    }
    
    var filterAllMedia: CMActionEntity {
        CMActionEntity(type: .filter(actionType: .allMedia),
                       state: currentFilterType() == .allMedia ? .on : .off)
    }
    
    var filterImages: CMActionEntity {
        CMActionEntity(type: .filter(actionType: .images),
                       state: currentFilterType() == .images ? .on : .off)
    }
    
    var filterVideos: CMActionEntity {
        CMActionEntity(type: .filter(actionType: .videos),
                       state: currentFilterType() == .videos ? .on : .off)
    }
    
    // MARK: - Quick Folder Actions
    
    var info: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .info))
    }
    
    var download: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .download))
    }
    
    var shareLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .shareLink))
    }
    
    var manageLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .manageLink))
    }
    
    var removeLink: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .removeLink))
    }
    
    var leaveSharing: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .leaveSharing))
    }
    
    var removeSharing: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .removeSharing))
    }
    
    var copy: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .copy))
    }
    
    var shareFolder: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .shareFolder))
    }
    
    var manageFolder: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .manageFolder))
    }
    
    var rename: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .rename))
    }
    
    var sendToChat: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .sendToChat))
    }
    
    var saveToPhotos: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .saveToPhotos))
    }
    
    var hide: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .hide))
    }
    
    var unhide: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .unhide))
    }
    
    var settings: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .settings))
    }
    
    var dispute: CMActionEntity {
        CMActionEntity(type: .quickActions(actionType: .dispute))
    }
    
    // MARK: - Rubbish Bin Actions
    
    var restore: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .restore))
    }
    
    var infoRubbishBin: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .info))
    }
    
    var versions: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .versions))
    }
    
    var remove: CMActionEntity {
        CMActionEntity(type: .rubbishBin(actionType: .remove))
    }
    
    // MARK: - Chat Actions
    
    func chatStatus(_ status: ChatStatusEntity) -> CMActionEntity {
        CMActionEntity(type: .chatStatus(actionType: status),
                       state: currentChatStatus() == status ? .on : .off)
    }
    
    func doNotDisturb(option: DNDTurnOnOptionEntity) -> CMActionEntity {
        CMActionEntity(type: .chatDoNotDisturbEnabled(optionType: option))
    }
    
    // MARK: - My QR Code Actions
    
    var share: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .share))
    }
    
    var qrSettings: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .qrSettings))
    }
    
    var resetQR: CMActionEntity {
        CMActionEntity(type: .qr(actionType: .resetQR))
    }
    
    // MARK: - Meeting
    
    var startMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .startMeeting))
    }
    
    var joinMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .joinMeeting))
    }
    
    var scheduleMeeting: CMActionEntity {
        CMActionEntity(type: .meeting(actionType: .scheduleMeeting))
    }
    
    // MARK: - Album
    
    var selectAlbumCover: CMActionEntity {
        CMActionEntity(type: .album(actionType: .selectAlbumCover))
    }
    
    var delete: CMActionEntity {
        CMActionEntity(type: .album(actionType: .delete))
    }
    
    // MARK: - Video Playlist
    
    var addVideosToVideoPlaylistContent: CMActionEntity {
        CMActionEntity(type: .videoPlaylist(actionType: .addVideosToVideoPlaylistContent))
    }
    
    var deleteVideoPlaylist: CMActionEntity {
        CMActionEntity(type: .videoPlaylist(actionType: .delete))
    }
}
