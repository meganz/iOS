

enum UserImageLoadError: Error {
    case generic
    case base64EncodingError
    case unableToFetch
}
