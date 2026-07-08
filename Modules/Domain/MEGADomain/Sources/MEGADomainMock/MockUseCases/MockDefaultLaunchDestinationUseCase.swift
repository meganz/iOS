import MEGADomain

public final class MockDefaultLaunchDestinationUseCase: DefaultLaunchDestinationUseCaseProtocol {

    public private(set) var selectedDestination: LaunchDestinationEntity
    public private(set) var hasSelectedDestination: Bool
    public private(set) var setDestinationCallCount = 0
    public var messages = [Message]()

    public init(
        selectedDestination: LaunchDestinationEntity = .home,
        hasSelectedDestination: Bool = false
    ) {
        self.selectedDestination = selectedDestination
        self.hasSelectedDestination = hasSelectedDestination
    }

    public func setDestination(_ destination: LaunchDestinationEntity) {
        setDestinationCallCount += 1
        selectedDestination = destination
        hasSelectedDestination = true
        messages.append(.setDestination(destination))
    }
}

extension MockDefaultLaunchDestinationUseCase {

    // MARK: nested type

    public enum Message: Equatable {
        case setDestination(LaunchDestinationEntity)
    }
}
