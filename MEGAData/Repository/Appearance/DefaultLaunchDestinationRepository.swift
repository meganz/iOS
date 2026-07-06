import MEGADomain

struct DefaultLaunchDestinationRepository: DefaultLaunchDestinationRepositoryProtocol {

    static var newRepo: DefaultLaunchDestinationRepository {
        DefaultLaunchDestinationRepository()
    }

    func destination(for rawValue: String) -> LaunchDestinationEntity? {
        LaunchDestinationEntity.allCases.first { self.rawValue(for: $0) == rawValue }
    }

    func rawValue(for entity: LaunchDestinationEntity) -> String {
        switch entity {
        case .home: "home"
        case .drive: "cloudDrive"
        case .media: "cameraUploads"
        case .chat: "chat"
        case .sharedItems: "sharedItems"
        case .favourites: "favourites"
        case .offline: "offline"
        }
    }
}
