import MEGADomain

public final class MockDefaultLaunchDestinationRepository: DefaultLaunchDestinationRepositoryProtocol {
    public static var newRepo: MockDefaultLaunchDestinationRepository {
        MockDefaultLaunchDestinationRepository()
    }

    private let storedValues: [LaunchDestinationEntity: String]

    public init(storedValues: [LaunchDestinationEntity: String] = [:]) {
        self.storedValues = storedValues
    }

    public func destination(for rawValue: String) -> LaunchDestinationEntity? {
        storedValues.first { $0.value == rawValue }?.key
    }

    public func rawValue(for entity: LaunchDestinationEntity) -> String {
        storedValues[entity] ?? ""
    }
}
