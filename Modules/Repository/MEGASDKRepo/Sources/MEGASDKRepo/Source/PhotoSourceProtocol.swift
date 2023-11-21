import MEGADomain

public protocol PhotoSourceProtocol: Actor {
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
    func removeAllPhotos()
}
