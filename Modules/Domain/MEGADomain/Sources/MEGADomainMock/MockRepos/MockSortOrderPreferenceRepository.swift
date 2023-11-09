import MEGADomain

public final class MockSortOrderPreferenceRepository: SortOrderPreferenceRepositoryProtocol {
    public static var newRepo: MockSortOrderPreferenceRepository {
        MockSortOrderPreferenceRepository()
    }
    
    public var keySortedEntity: [SortOrderPreferenceKeyEntity: SortOrderEntity] = [:]
    public var nodeSortedEntity: [NodeEntity: SortOrderEntity] = [:]
    
    public var saveSortOrderForKey_calledCount: Int = 0
    public var saveSortOrderForNode_calledCount: Int = 0

    private let megaSortOrderTypeCodes: [SortOrderEntity: Int]
    private let sortOrderPreferenceBasisCodes: [SortingPreferenceBasisEntity: Int]
    
    public init(
        megaSortOrderTypeCodes: [SortOrderEntity: Int] = [:],
        sortOrderPreferenceBasisCodes: [SortingPreferenceBasisEntity: Int] = [:],
        keySortedEntity: [SortOrderPreferenceKeyEntity: SortOrderEntity] = [:],
        nodeSortedEntity: [NodeEntity: SortOrderEntity] = [:]) {
            self.megaSortOrderTypeCodes = megaSortOrderTypeCodes
            self.sortOrderPreferenceBasisCodes = sortOrderPreferenceBasisCodes
            self.keySortedEntity = keySortedEntity
            self.nodeSortedEntity = nodeSortedEntity
    }
    
    public func sortOrderPreferenceBasis(for code: Int) -> SortingPreferenceBasisEntity? {
        sortOrderPreferenceBasisCodes.first(where: { $0.value == code})?.key
    }
    
    public func megaSortOrderTypeCode(for sortOrder: SortOrderEntity) -> Int {
        megaSortOrderTypeCodes[sortOrder] ?? -1
    }
    
    public func sortOrder(for megaSortOrderTypeCode: Int) -> SortOrderEntity? {
        megaSortOrderTypeCodes.first(where: { $0.value == megaSortOrderTypeCode})?.key
    }
    
    public func sortOrder(for key: SortOrderPreferenceKeyEntity) -> SortOrderEntity? {
        keySortedEntity[key]
    }
    
    public func sortOrder(for node: NodeEntity) -> SortOrderEntity? {
        nodeSortedEntity[node]
    }
    
    public func save(sortOrder: SortOrderEntity, for key: SortOrderPreferenceKeyEntity) {
        saveSortOrderForKey_calledCount += 1
        keySortedEntity[key] = sortOrder
    }
    
    public func save(sortOrder: SortOrderEntity, for node: NodeEntity) {
        saveSortOrderForNode_calledCount += 1
        nodeSortedEntity[node] = sortOrder
    }
}
