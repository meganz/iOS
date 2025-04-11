/// Protocol defining the operations related to rubbish bin settings management.
///
/// This protocol provides methods to clean the rubbish bin, synchronize with the SDK,
/// and manage the auto-purge period for the rubbish bin.
public protocol RubbishBinSettingsRepositoryProtocol: RepositoryProtocol, Sendable {
    
    /// Cleans the rubbish bin by permanently deleting all items within it.
    ///
    /// - Throws: An error if the operation fails.
    func cleanRubbishBin() async throws
    
    /// Synchronizes the repository with the SDK to ensure the latest state is reflected.
    ///
    /// - Throws: An error if the synchronization fails.
    func catchupWithSDK() async throws
    
    /// Sets the auto-purge period for the rubbish bin.
    ///
    /// - Parameter days: The number of days after which items in the rubbish bin will be automatically purged.
    func setRubbishBinAutopurgePeriod(in days: Int) async
    
    /// Retrieves the current auto-purge period for the rubbish bin.
    ///
    /// - Returns: A `RubbishBinSettingsEntity` containing the auto-purge period and related settings.
    /// - Throws: An error if the operation fails.
    func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity
}
