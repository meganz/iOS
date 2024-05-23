extension SetEntity {
    func toVideoPlaylistEntity(type: VideoPlaylistEntityType, sharedLinkStatus: SharedLinkStatusEntity = .exported(false)) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: handle,
            name: name,
            count: 0,
            type: type,
            creationTime: creationTime,
            modificationTime: modificationTime,
            sharedLinkStatus: sharedLinkStatus
        )
    }
}
