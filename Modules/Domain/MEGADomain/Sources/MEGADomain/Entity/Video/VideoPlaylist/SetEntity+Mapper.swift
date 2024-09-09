extension SetEntity {
    func toVideoPlaylistEntity(type: VideoPlaylistEntityType, sharedLinkStatus: SharedLinkStatusEntity = .exported(false), count: Int = 0) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            setIdentifier: SetIdentifier(handle: handle),
            name: name,
            count: count,
            type: type,
            creationTime: creationTime,
            modificationTime: modificationTime,
            sharedLinkStatus: sharedLinkStatus
        )
    }
}
