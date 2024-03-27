extension SetEntity {
    func toVideoPlaylistEntity(type: VideoPlaylistEntityType) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: handle,
            name: name,
            count: 0,
            type: type,
            creationTime: creationTime,
            modificationTime: modificationTime,
            sharedLinkStatus: .exported(isExported)
        )
    }
}
