import Foundation

public struct SearchFilterEntity: Sendable {
    public struct TimeFrame: Equatable, Sendable {
        public let startDate: Date
        public let endDate: Date

        public init(startDate: Date, endDate: Date) {
            self.startDate = startDate
            self.endDate = endDate
        }
    }
    
    /// Set option for filtering by name. Contains a name or an expression using wildcard. If nil set, it will return all results ignoring the name.
    public let searchText: String?
    /// Parent for retrieving nodes below the given  ancestor. If not set, nodes will not be restricted to a particular ancestor.
    public let parentNode: NodeEntity?
    /// Indicates if results should be found recursively through child nodes or focus only at the top level location of passed parent node or root.
    public let recursive: Bool
    /// Indicates if cancellation token should be stored to be cancelled at a later time, via cancelSearch()
    public let supportCancel: Bool
    /// Order for the returned results to be in.
    public let sortOrderType: SortOrderEntity
    /// Filter option to return nodes that only match the given format.
    public let formatType: NodeFormatEntity
    /// Filter option to decide if search should exclude sensitive nodes from the final result.
    public let excludeSensitive: Bool
    
    public let nodeTypeEntity: NodeTypeEntity?
    
    public let modificationTimeFrame: TimeFrame?
    
    public init(
        searchText: String? = nil,
        parentNode: NodeEntity? = nil,
        recursive: Bool,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        formatType: NodeFormatEntity,
        excludeSensitive: Bool,
        nodeTypeEntity: NodeTypeEntity? = nil,
        modificationTimeFrame: SearchFilterEntity.TimeFrame? = nil
    ) {
        self.searchText = searchText
        self.parentNode = parentNode
        self.recursive = recursive
        self.supportCancel = supportCancel
        self.sortOrderType = sortOrderType
        self.formatType = formatType
        self.excludeSensitive = excludeSensitive
        self.nodeTypeEntity = nodeTypeEntity
        self.modificationTimeFrame = modificationTimeFrame
    }
}
