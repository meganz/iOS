import MEGADomain

public extension RequestResponseEntity {
    init(
        requestEntity: RequestEntity = .init(type: .accountDetails),
        error: ErrorEntity = .init(type: .ok),
        isTesting: Bool = true
    ) {
        self.init(
            requestEntity: requestEntity,
            error: error
        )
    }
}
