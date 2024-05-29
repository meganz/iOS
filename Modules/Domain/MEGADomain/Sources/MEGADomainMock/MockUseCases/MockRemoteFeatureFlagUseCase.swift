import MEGADomain

public actor MockRemoteFeatureFlagUseCase: RemoteFeatureFlagUseCaseProtocol {
    private let valueToReturn: Bool
    
    public init(valueToReturn: Bool) {
        self.valueToReturn = valueToReturn
    }
    
    private var flagsPassedIn: [RemoteFeatureFlag] = []
    
    func capturedFlags() async -> [RemoteFeatureFlag] {
        flagsPassedIn
    }
    
    public func isFeatureFlagEnabled(for flag: RemoteFeatureFlag) async -> Bool {
        flagsPassedIn.append(flag)
        return valueToReturn
    }
}
