/// Repository that provides the domain access to the sorting order  information used in the application. This will communicate with internal data stores to fetch the desired appearance models to support the requested context.
public protocol SortOrderPreferenceRepositoryProtocol: RepositoryProtocol {
    
    ///  Fetches the SortingPreferenceBasisEntity for the given code, if no matching value exists it returns nil
    /// - Parameter code: Integer representation of SortingPreferenceBasisEntity  identifier
    /// - Returns: SortingPreferenceBasisEntity, if the integer representation is supported, else return nil
    func sortOrderPreferenceBasis(for code: Int) -> SortingPreferenceBasisEntity?
    
    ///  Fetches the identifying Integer representation of a SortOrderEntity.
    /// - Parameter sortOrder: SortOrderEntity to be parsed into a Integer representation
    /// - Returns: Integer representation of a SortOrderEntity
    func megaSortOrderTypeCode(for sortOrder: SortOrderEntity) -> Int
    
    ///  Fetches the SortOrderEntity for the give MEGASortOrderType code, if no matching value exists it returns nil
    /// - Parameter megaSortOrderTypeCode: Integer representation of MEGASortOrderType identifier
    /// - Returns: SortOrderEntity, if the integer representation is supported, else return nil
    func sortOrder(for megaSortOrderTypeCode: Int) -> SortOrderEntity?

    /// Fetches the desired sort order for the given preference key, if an appearance model exists for the given key. Depending on users desired setting for applying sort logic. This may not fetch based on the passed key but instead use a global sort order.
    /// - Parameter key: SortOrderPreferenceKeyEntity associated with a feature or context of the application
    /// - Returns: SortOrderEntity that describes the order in which the context should be applied in
    func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity?
    
    /// Fetches the desired sort order for the given NodeEntity/Folder, if an appearance model exists for the given node. Depending on users desired setting for applying sort logic. This may not fetch based on the passed node but instead use a global sort order.
    /// - Parameter nodeHandle: HandleEntity of the node associated with a parent folder node
    /// - Returns: SortOrderEntity that describes the order in which the contents of a parent folder should be sorted
    func sortOrder(for nodeHandle: HandleEntity) -> SortOrderEntity?
    
    /// Save the given sortOrder appearance information associated to the given key. Depending on users desired setting for applying sort logic. This may not save  on the passed key but instead save at a global associated level.
    /// - Parameters:
    ///   - sortOrder: The desired sort order appearance to save against the associated key value.
    ///   - key: Key identifying on which target to save this sort order preference against.
    func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity)
    
    /// Save the given sortOrder appearance information associated to the given key. Depending on users desired setting for applying sort logic. This may not save  on the passed node but instead save at a global associated level.
    /// - Parameters:
    ///   - sortOrder: The desired sort order appearance to save against the associated key value.
    ///   - nodeHandle: HandleEntity of the node identifying on which target to save this sort order preference against.
    func save(sortOrder: SortOrderEntity, for nodeHandle: HandleEntity)
}
