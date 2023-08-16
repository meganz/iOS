import MEGADomain

public struct MockCopyrightUseCase: CopyrightUseCaseProtocol {
    private let shouldAutoApprove: Bool
    
    public init(shouldAutoApprove: Bool = true) {
        self.shouldAutoApprove = shouldAutoApprove
    }
    
    public func shouldAutoApprove() async -> Bool {
        shouldAutoApprove
    }
}
