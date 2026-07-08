import MEGAPreference

public protocol DefaultLaunchDestinationUseCaseProtocol {
    var selectedDestination: LaunchDestinationEntity { get }
    var hasSelectedDestination: Bool { get }
    func setDestination(_ destination: LaunchDestinationEntity)
}

public struct DefaultLaunchDestinationUseCase: DefaultLaunchDestinationUseCaseProtocol {

    private enum PreferenceKey: String, PreferenceKeyProtocol {
        case defaultLaunchDestination
    }

    @PreferenceWrapper(key: PreferenceKey.defaultLaunchDestination, defaultValue: nil)
    private var storedRawValue: String?

    private let repository: any DefaultLaunchDestinationRepositoryProtocol

    public init(
        preferenceUseCase: some PreferenceUseCaseProtocol,
        repository: some DefaultLaunchDestinationRepositoryProtocol
    ) {
        self.repository = repository
        $storedRawValue.useCase = preferenceUseCase
    }

    public var selectedDestination: LaunchDestinationEntity {
        guard let storedRawValue,
              let destination = repository.destination(for: storedRawValue) else {
            return .home
        }
        return destination
    }

    public var hasSelectedDestination: Bool {
        storedRawValue != nil
    }

    public func setDestination(_ destination: LaunchDestinationEntity) {
        storedRawValue = repository.rawValue(for: destination)
    }
}
