import Foundation

public protocol UserAlbumRepositoryProtocol: RepositoryProtocol {
    // MARK: - Album
    
    /// Fetch all user albums
    /// - Returns: User albums
    func albums() async -> [SetEntity]
    
    /// Fetch particular user album content
    /// - Parameter id: User album id
    /// - Returns: The particular user album content
    func albumContent(by id: HandleEntity) async -> [SetElementEntity]
    
    /// Create a user album
    /// - Parameter name: The user album name, can be nil
    /// - Throws: AlbumErrorEntity
    /// - Returns: Created user album
    func createAlbum(_ name: String?) async throws -> SetEntity
    
    /// Update user album name
    /// - Parameters:
    ///   - name: The new user album name
    ///   - id: The user album id
    /// - Throws: AlbumErrorEntity
    /// - Returns: The new name of user album
    func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String
    
    /// Remove the user album
    /// - Parameter id: The user album id to remove
    /// - Throws: AlbumErrorEntity
    /// - Returns: The id of removed user album
    func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity
}
