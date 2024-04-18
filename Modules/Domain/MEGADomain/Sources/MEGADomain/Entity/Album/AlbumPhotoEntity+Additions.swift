public extension Sequence where Element == AlbumPhotoEntity {
    func latestModifiedPhoto() -> NodeEntity? {
        self.max(by: { lhs, rhs in
            if lhs.photo.modificationTime == rhs.photo.modificationTime {
                lhs.id < rhs.id
            } else {
                lhs.photo.modificationTime < rhs.photo.modificationTime
            }
        })?.photo
    }
}
