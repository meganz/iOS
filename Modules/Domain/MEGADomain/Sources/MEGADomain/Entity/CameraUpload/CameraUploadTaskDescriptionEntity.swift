/// A typealias representing a camera upload task description.
///
/// The format of this string is `"<localIdentifier>|<chunkIndex>|<totalChunks>"`.
/// It uniquely identifies a chunk upload task within a larger camera upload process.
public typealias CameraUploadTaskDescriptionEntity = String

extension CameraUploadTaskDescriptionEntity {
    
    /// Parses the string representation of a camera upload task into a `CameraUploadTaskInfoEntity`.
    ///
    /// The string is expected to have the format `"<localIdentifier>|<chunkIndex>|<totalChunks>"`.
    ///
    /// - Returns: A `CameraUploadTaskInfoEntity` if the string is correctly formatted,
    ///   or `nil` if parsing fails (e.g., invalid format or non-numeric chunk values).
    public func parseTaskInfo() -> CameraUploadTaskInfoEntity? {
        let components = self.components(separatedBy: "|")
        guard components.count == 3,
              let chunkIndex = Int(components[1]),
              let totalChunks = Int(components[2]) else {
            return nil
        }
        
        return CameraUploadTaskInfoEntity(
            localIdentifier: components[0],
            chunkIndex: chunkIndex,
            totalChunks: totalChunks
        )
    }
    
    /// Creates a `CameraUploadTaskDescriptionEntity` string representation from its components.
    ///
    /// The resulting string will have the format `"<localIdentifier>|<chunkIndex>|<totalChunks>"`.
    ///
    /// - Parameters:
    ///   - localIdentifier: The local identifier of the asset being uploaded.
    ///   - chunkIndex: The index of the chunk within the total number of chunks.
    ///   - totalChunks: The total number of chunks for the asset.
    ///
    /// - Returns: A string representation of the upload task.
    public static func create(localIdentifier: String, chunkIndex: Int, totalChunks: Int) -> CameraUploadTaskDescriptionEntity {
        "\(localIdentifier)|\(chunkIndex)|\(totalChunks)"
    }
}
