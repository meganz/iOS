import Photos

public protocol CameraUploadRecordStore: Sendable {
    /// Fetches camera asset upload records.
    ///
    /// - Parameters:
    ///   - localIdentifier: The optional local identifier of an asset to start fetching from.
    ///                      Pass `nil` to start from the beginning.
    ///   - isForward: A Boolean value indicating the fetch direction. `true` for forward,
    ///              `false` for backward.
    ///   - limit: An optional maximum number of records to return. Pass `nil` for no limit.
    ///   - statuses: An array of status integers to filter the uploads by.
    ///   - mediaTypes: An array of media type integers to filter the uploads by.
    ///
    /// - Returns: An array of `AssetUploadRecordDTO` matching the criteria.
    /// - Throws: An error if the fetch fails.
    func fetchAssetUploads(
        startingFrom cursor: QueuedCameraUploadCursorDTO?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusDTO],
        mediaTypes: [PHAssetMediaType]
    ) async throws -> [AssetUploadRecordDTO]
    
    /// Retrieves the file names associated with a set of camera asset uploads.
    ///
    /// - Parameter identifiers: A set of local identifiers of assets to retrieve file names for.
    /// - Returns: An array of `AssetUploadFileNameRecordDTO` containing the file names.
    /// - Throws: An error if the fetch fails.
    func fetchAssetUploadFileNames(
        forLocalIdentifiers identifiers: Set<String>
    ) async throws -> Set<AssetUploadFileNameRecordDTO>
}
