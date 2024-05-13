import MEGADomain

public protocol PhotoLocalSourceProtocol: Actor {
    /// Flag to indicate that the cache was forcefully cleared
    /// - Returns: Bool
    var wasForcedCleared: Bool { get }
    /// Retrieve all photos
    var photos: [NodeEntity] { get }
    /// Store photos in source location
    func setPhotos(_ photos: [NodeEntity])
    ///  Photo for node handle
    /// - Parameter handle: HandleEntity of the photo
    /// - Returns: NodeEntity or nil if not found.
    func photo(forHandle handle: HandleEntity) -> NodeEntity?
    /// Remove photo from source for node handle
    /// - Parameter handle: HandleEntity for photo to invalidate
    func removePhoto(forHandle handle: HandleEntity)
    /// Remove all photos from source
    /// - Parameter forced: Flag to indicate that it was forcefully cleared
    func removeAllPhotos(forced: Bool)
    /// Clear the forced flag
    func clearForcedFlag()
}
