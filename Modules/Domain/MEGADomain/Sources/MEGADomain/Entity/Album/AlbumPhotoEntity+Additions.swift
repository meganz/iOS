public extension Sequence where Element == AlbumPhotoEntity {
    func latestModifiedPhoto(excludeSensitives: Bool = false) -> NodeEntity? {
        let sequence: any Sequence<Element> = excludeSensitives ? self.filter { !$0.isSensitive } : self
        return sequence.filter({ excludeSensitives ? !$0.isSensitive : true })
            .max(by: { lhs, rhs in
                if lhs.photo.modificationTime == rhs.photo.modificationTime {
                    lhs.id < rhs.id
                } else {
                    lhs.photo.modificationTime < rhs.photo.modificationTime
                }
            })?.photo
    }
}
