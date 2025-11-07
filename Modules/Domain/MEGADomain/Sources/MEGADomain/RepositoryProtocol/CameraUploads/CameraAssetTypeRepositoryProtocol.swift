public protocol CameraAssetTypeRepositoryProtocol: Sendable {
    /// Loads the media type of a camera asset for a given local identifier.
    ///
    /// - Parameter localIdentifier: The local identifier of the asset in the Photos library.
    /// - Returns: An `AssetMediaTypeEntity` containing the mapped media format and burst information,
    ///   or `nil` if the asset cannot be found.
    func loadAssetType(for localIdentifier: String) -> AssetMediaTypeEntity?
}
