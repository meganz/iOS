import Foundation
import MEGADomain
import MEGAL10n

@MainActor
public final class NodeTagsCellControllerModel {
    private let accountUseCase: any AccountUseCaseProtocol
    private let node: NodeEntity
    private(set) lazy var cellViewModel = NodeTagsCellViewModel(node: node)
    
    var selectedTags: Set<String> {
        Set(node.tags)
    }
    
    var isExpiredBusinessOrProFlexiAccount: Bool {
        accountUseCase.hasExpiredBusinessAccount() || accountUseCase.hasExpiredProFlexiAccount()
    }

    var featureUnavailableDescription: String {
        if accountUseCase.currentAccountDetails?.proLevel == .proFlexi {
            Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.proFlexi
        } else if accountUseCase.isMasterBusinessAccount {
            Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.masterBusiness
        } else {
            Strings.Localizable.CloudDrive.NodeInfo.NodeTags.FeatureUnavailable.Popup.Description.AccountType.memberBusiness
        }
    }

    public init(node: NodeEntity, accountUseCase: some AccountUseCaseProtocol) {
        self.node = node
        self.accountUseCase = accountUseCase
    }
}
