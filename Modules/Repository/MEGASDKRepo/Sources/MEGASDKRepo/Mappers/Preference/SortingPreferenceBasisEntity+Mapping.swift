import MEGADomain

public extension SortingPreferenceBasisEntity {

    init?(sortingPreferenceBasisEntityCode: Int) {
        switch sortingPreferenceBasisEntityCode {
        case 0:
            self = .perFolder
        case 1:
            self = .sameForAll
        default:
            return nil
        }
    }
}
