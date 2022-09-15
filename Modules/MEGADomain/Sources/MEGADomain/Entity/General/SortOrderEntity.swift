public enum SortOrderEntity: CaseIterable {
    case none
    case defaultAsc
    case defaultDesc
    case sizeAsc
    case sizeDesc
    case creationAsc
    case creationDesc
    case modificationAsc
    case modificationDesc
    case photoAsc
    case photoDesc
    case videoAsc
    case videoDesc
    case linkCreationAsc
    case linkCreationDesc
    case labelAsc
    case labelDesc
    case favouriteAsc
    case favouriteDesc
    
    public static let allValid: [SortOrderEntity] = [
        .defaultAsc,
        .defaultDesc,
        .sizeDesc,
        .sizeAsc,
        .modificationDesc,
        .modificationAsc,
        .labelAsc,
        .favouriteAsc
    ]
}
