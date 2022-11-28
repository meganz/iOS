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
    
    // MARK: - Album Content
    
    /// Add photos to the album
    /// - Parameters:
    ///   - id: Album id
    ///   - nodes: Nodes need to be added to the album
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> [SetElementEntity]
    
    /// Update album element name
    /// - Parameters:
    ///   - albumId: The album id
    ///   - elementId: The album element id
    ///   - name: The album element's new name
    /// - Returns: The new name
    func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String
    
    /// Update album element order
    /// - Parameters:
    ///   - albumId: The album id
    ///   - elementId: The album element id
    ///   - order: The album element's new order
    /// - Returns: The new order
    func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64
    
    /// Remove the photo from the album
    /// - Parameters:
    ///   - albumId: The album id
    ///   - elementId: The album element to be removed
    /// - Returns: The removed element's id
    func deleteAlbumElement(albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity
}
