import Foundation

public protocol UserAlbumRepositoryProtocol: RepositoryProtocol {
    // MARK: - Album
    
    /// Fetch all user albums
    /// - Returns: User albums
    func albums() async -> [SetEntity]
    
    /// Fetch particular user album content
    /// - Parameters:
    ///   - id: User album id
    ///   - includeElementsInRubbishBin: Filter out Elements in Rubbish Bin
    /// - Returns: The particular user album content
    func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity]
    
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
    ///   - id: The album id
    ///   - nodes: The nodes need to be added to the album
    /// - Returns: The CreateSetElementResultEntity
    ///   - success: means the number of photos added to the album successfully
    ///   - failure: means the number of photos added to the album unsuccessfully
    func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity
    
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
    
    ///  Remove the photo from the album
    /// - Parameters:
    ///   - albumId: The album id
    ///   - elementIds: Elements needs to be deleted
    /// - Returns: The CreateSetElementResultEntity
    ///   - success: means the number of photos deleted from the album successfully
    ///   - failure: means the number of photos deleted from the album unsuccessfully
    func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity
    
    // MARK: - Album Cover
    
    /// Update Album Cover
    /// - Parameters:
    ///   - albumId: The album need to be updated
    ///   - elementId: The album element to be set as cover
    /// - Returns: The album element id to be set as the new cover
    func updateAlbumCover(for albumId: HandleEntity,elementId: HandleEntity) async throws -> HandleEntity
}
