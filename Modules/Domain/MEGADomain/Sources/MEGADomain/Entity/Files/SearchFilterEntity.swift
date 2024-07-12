import Foundation

public struct SearchFilterEntity: Sendable, Equatable {
    public struct TimeFrame: Equatable, Sendable {
        public let startDate: Date
        public let endDate: Date

        public init(startDate: Date, endDate: Date) {
            self.startDate = startDate
            self.endDate = endDate
        }
    }
    
    public enum FavouriteFilterOption: Sendable, Equatable {
        ///  Both favourites and non favourites are considered
        case disabled
        /// Only favourites
        case onlyFavourites
        /// Exclude favourite nodes from result
        case excludeFavourites
    }
    
    public enum SensitiveFilterOption: Sendable, Equatable {
        ///  No filtering is applied based on sensitivity of nodes and ancestral hierarchy
        case disabled
        /// Include non-sensitive nodes in search result, this excludes inherited sensitive nodes as well.
        case nonSensitiveOnly
        /// Include sensitive nodes in search result, this includes inherited sensitive nodes
        case sensitiveOnly
    }
    
    public enum SearchTargetLocation: Sendable, Equatable {
        /// Node target for retrieving nodes below this directory
        case parentNode(NodeEntity)
        /// Folder target for retrieving nodes below the directory
        case folderTarget(FolderTargetEntity)
    }
    
    /// Set option for filtering by name. Contains a name or an expression using wildcard. If nil set, it will return all results ignoring the name.
    public let searchText: String?
    /// Location to which the search will be restricted to. If an ancestor was explicitly set via parentNode, search under that particular ancestor.
    public let searchTargetLocation: SearchTargetLocation
    /// Indicates if results should be found recursively through child nodes or focus only at the top level location of passed parent node or root.
    public let recursive: Bool
    /// Indicates if cancellation token should be stored to be cancelled at a later time, via cancelSearch()
    public let supportCancel: Bool
    /// Order for the returned results to be in.
    public let sortOrderType: SortOrderEntity
    /// Filter option to return nodes that only match the given format.
    public let formatType: NodeFormatEntity
    /// Filter option to determine node inclusion based on sensitive criteria.
    public let sensitiveFilterOption: SensitiveFilterOption
    /// Filter option for filtering out nodes based on if node is marked favourite or not.
    public let favouriteFilterOption: FavouriteFilterOption
    
    /// Filter out results by node type.
    ///
    /// Note:
    /// - .unknown represents all node types
    public let nodeTypeEntity: NodeTypeEntity
    
    public let modificationTimeFrame: TimeFrame?
    
    private init(
        searchText: String? = nil,
        searchTargetLocation: SearchTargetLocation,
        recursive: Bool,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        formatType: NodeFormatEntity,
        sensitiveFilterOption: SensitiveFilterOption = .disabled,
        favouriteFilterOption: FavouriteFilterOption = .disabled,
        nodeTypeEntity: NodeTypeEntity = .unknown,
        modificationTimeFrame: SearchFilterEntity.TimeFrame? = nil
    ) {
        self.searchText = searchText
        self.searchTargetLocation = searchTargetLocation
        self.recursive = recursive
        self.supportCancel = supportCancel
        self.sortOrderType = sortOrderType
        self.formatType = formatType
        self.sensitiveFilterOption = sensitiveFilterOption
        self.favouriteFilterOption = favouriteFilterOption
        self.nodeTypeEntity = nodeTypeEntity
        self.modificationTimeFrame = modificationTimeFrame
    }
    
    /// Creates a SearchFilterEntity with a focus on creating a request to recursively search based on the params provided
    /// - Returns: SearchFilterEntity - To recursively search for results
    public static func recursive(
        searchText: String? = nil,
        searchTargetLocation: SearchTargetLocation,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        formatType: NodeFormatEntity,
        sensitiveFilterOption: SensitiveFilterOption = .disabled,
        favouriteFilterOption: FavouriteFilterOption = .disabled,
        nodeTypeEntity: NodeTypeEntity = .unknown,
        modificationTimeFrame: SearchFilterEntity.TimeFrame? = nil
    ) -> Self {
        self.init(searchText: searchText,
                  searchTargetLocation: searchTargetLocation,
                  recursive: true,
                  supportCancel: supportCancel,
                  sortOrderType: sortOrderType,
                  formatType: formatType,
                  sensitiveFilterOption: sensitiveFilterOption,
                  favouriteFilterOption: favouriteFilterOption,
                  nodeTypeEntity: nodeTypeEntity,
                  modificationTimeFrame: modificationTimeFrame)
    }
    
    /// Creates a SearchFilterEntity with a focus on creating a request to non-recursively search based on the params provided.
    /// This initializer differs from the recursive version, because a node entity is the only target location that can be provided to the SDK to perform a non-recursive search. FolderTargetEntity is not supported in this variation. So it is enforced to pass a target node entity.
    /// - Returns: SearchFilterEntity - To non-recursively search for results
    public static func nonRecursive(
        searchText: String? = nil,
        searchTargetNode: NodeEntity,
        supportCancel: Bool,
        sortOrderType: SortOrderEntity,
        formatType: NodeFormatEntity,
        sensitiveFilterOption: SensitiveFilterOption = .disabled,
        favouriteFilterOption: FavouriteFilterOption = .disabled,
        nodeTypeEntity: NodeTypeEntity = .unknown,
        modificationTimeFrame: SearchFilterEntity.TimeFrame? = nil
    ) -> Self {
        self.init(searchText: searchText,
                  searchTargetLocation: .parentNode(searchTargetNode), 
                  recursive: false,
                  supportCancel: supportCancel,
                  sortOrderType: sortOrderType, 
                  formatType: formatType,
                  sensitiveFilterOption: sensitiveFilterOption, 
                  favouriteFilterOption: favouriteFilterOption,
                  nodeTypeEntity: nodeTypeEntity,
                  modificationTimeFrame: modificationTimeFrame)
    }
}
