import MEGAAppSDKRepo
import MEGADomain

/// Drives the bottom bar of `RecentActionBucketItemsView` during multi-select edit mode.
///
/// Derives a `Configuration` from the bucket's `nodeAccessType` and a backup-node
/// check performed via `BackupsUseCase`, determining which action buttons to display
/// and whether to show the "More" sheet trigger. The configuration is computed once
/// on first access and remains constant for the lifetime of the view.
@MainActor
final class RecentActionBucketItemsBottomBarViewModel {
    /// Describes the bottom bar layout for a given bucket access context.
    ///
    /// `actions` and `showsMoreButton` are computed together from the bucket's
    /// `nodeAccessType` and a `BackupsUseCase` backup-node check, so they always
    /// represent a consistent state.
    struct Configuration {
        /// The ordered list of node actions rendered as toolbar buttons.
        /// Each action maps directly to a `NodesAction` when tapped.
        let actions: [RecentActionBottomBarAction]

        /// Whether the "More" button should be appended after the action buttons.
        /// The "More" button is handled separately because it presents a
        /// `NodeActionViewController` rather than dispatching a `NodesAction`.
        let showsMoreButton: Bool
    }

    private let bucket: RecentActionBucketEntity
    private let backupsUseCase: any BackupsUseCaseProtocol

    lazy var configuration: Configuration = {
        let isBackupNode = bucket.parent.map { backupsUseCase.isBackupNode($0) } ?? false
        return switch bucket.nodeAccessType {
        case .read, .readWrite:
            if isBackupNode {
                Configuration(actions: [.download, .shareLink], showsMoreButton: true)
            } else {
                Configuration(actions: [.download, .copy], showsMoreButton: false)
            }
        case .full:
            Configuration(actions: [.download, .copy, .move, .moveToRubbishBin], showsMoreButton: false)
        case .owner:
            if isBackupNode {
                Configuration(actions: [.download, .shareLink], showsMoreButton: true)
            } else {
                Configuration(actions: [.download, .shareLink, .move, .moveToRubbishBin], showsMoreButton: true)
            }
        default:
            Configuration(actions: [], showsMoreButton: false)
        }
    }()

    init(
        bucket: RecentActionBucketEntity,
        backupsUseCase: some BackupsUseCaseProtocol = BackupsUseCase(
            backupsRepository: BackupsRepository.newRepo,
            nodeRepository: NodeRepository.newRepo
        )
    ) {
        self.bucket = bucket
        self.backupsUseCase = backupsUseCase
    }
}
