public enum SortOrderEntity: CaseIterable, Sendable {
    case none
    case defaultAsc
    case defaultDesc
    case sizeAsc
    case sizeDesc
    case creationAsc
    case creationDesc
    case modificationAsc
    case modificationDesc
    case linkCreationAsc
    case linkCreationDesc
    case labelAsc
    case labelDesc
    case favouriteAsc
    case favouriteDesc
    case shareCreationAsc
    case shareCreationDesc

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
