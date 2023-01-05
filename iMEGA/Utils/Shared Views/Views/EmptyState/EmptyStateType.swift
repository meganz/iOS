enum EmptyStateType {
    case photos
    case timeline(image: UIImage?, title: String?, description: String?, buttonTitle: String?)
    case documents
    case audio
    case videos
    case allMedia
    case favourites
    case backups(searchActive: Bool)
    case album
}
