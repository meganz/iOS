public protocol CameraUploadAssetRepositoryProtocol: Sendable {
    /// Retrieves a list of camera upload entities, starting from a specified local identifier.
    ///
    /// This method is typically used to fetch a paginated or filtered list of uploads based on direction,
    /// status, and media type.
    ///
    /// - Parameters:
    ///   - localIdentifier: The local identifier from which to start fetching results.
    ///     If `nil`, results will start from the beginning or end depending on `isForward`.
    ///   - isForward: A Boolean value indicating the direction of retrieval.
    ///     Pass `true` to fetch uploads after the given identifier, or `false` to fetch before it.
    ///   - limit: The maximum number of results to return.
    ///     If `nil`, all matching uploads are returned.
    ///   - statuses: The list of upload statuses to filter by.
    ///   - mediaTypes: The list of media types to include in the results.
    ///
    /// - Returns: An array of `CameraAssetUploadEntity` objects matching the given filters.
    ///
    /// - Throws: An error if fetching uploads fails.
    func uploads(
        startingFrom localIdentifier: String?,
        isForward: Bool,
        limit: Int?,
        statuses: [CameraAssetUploadStatusEntity],
        mediaTypes: [PhotoAssetMediaTypeEntity]
    ) async throws -> [CameraAssetUploadEntity]
    
    /// Retrieves detailed file information for the given local identifiers.
    ///
    /// This method is typically used to obtain metadata about specific files
    /// such as name, size, or creation details.
    ///
    /// - Parameter identifiers: A set of local identifiers representing the files to look up.
    ///
    /// - Returns: An array of `CameraUploadFileDetailsEntity` objects containing detailed file information.
    ///
    /// - Throws: An error if retrieving file details fails.
    func fileDetails(
        forLocalIdentifiers identifiers: Set<String>
    ) async throws -> [CameraUploadFileDetailsEntity]
}
