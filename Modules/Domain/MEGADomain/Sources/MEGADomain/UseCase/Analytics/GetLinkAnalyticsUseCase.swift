import Foundation

public protocol GetLinkAnalyticsUseCaseProtocol {
    func sendDecryptionKey(nodeType: NodeTypeEntity, isOn: Bool)
    func setExpiryDate(nodeType: NodeTypeEntity, isOn: Bool)
    func setPassword(nodeType: NodeTypeEntity)
    func confirmPassword(nodeType: NodeTypeEntity)
    func resetPassword(nodeType: NodeTypeEntity)
    func removePassword(nodeType: NodeTypeEntity)
    func shareLink(nodeTypes: [NodeTypeEntity])
    func getLink(nodeTypes: [NodeTypeEntity])
    func proFeatureSeePlans(nodeType: NodeTypeEntity)
    func proFeatureNotNow(nodeType: NodeTypeEntity)
    func encrypt(nodeType: NodeTypeEntity)
}

public struct GetLinkAnalyticsUseCase<T: AnalyticsRepositoryProtocol>: GetLinkAnalyticsUseCaseProtocol {
    private let repo: T

    public init(repository: T) {
        repo = repository
    }

    public func sendDecryptionKey(nodeType: NodeTypeEntity, isOn: Bool) {
        switch (nodeType, isOn) {
        case (.folder, true): repo.sendAnalyticsEvent(.getLink(.sendDecryptionKeySeparateForFolderEnabled))
        case (.file, true): repo.sendAnalyticsEvent(.getLink(.sendDecryptionKeySeparateForFileEnabled))
        case (.folder, false): repo.sendAnalyticsEvent(.getLink(.sendDecryptionKeySeparateForFolderDisabled))
        case (.file, false): repo.sendAnalyticsEvent(.getLink(.sendDecryptionKeySeparateForFileDisabled))
        default: break
        }
    }

    public func setExpiryDate(nodeType: NodeTypeEntity, isOn: Bool) {
        switch (nodeType, isOn) {
        case (.folder, true): repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFolderEnabled))
        case (.file, true): repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFileEnabled))
        case (.folder, false): repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFolderDisabled))
        case (.file, false): repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFileDisabled))
        default: break
        }
    }

    public func setPassword(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.setPasswordForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.setPasswordForFolder))
        }
    }

    public func confirmPassword(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.confirmPasswordForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.confirmPaswordForFolder))
        }
    }

    public func resetPassword(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.resetPasswordForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.resetPasswordForFolder))
        }
    }

    public func removePassword(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.removePasswordForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.removePasswordForFolder))
        }
    }

    public func shareLink(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.shareFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.shareFolder))
        }
    }

    public func getLink(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.getLinkForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.getLinkForFolder))
        }
    }

    public func shareLink(nodeTypes: [NodeTypeEntity]) {
        guard let nodeType = nodeTypes.first, nodeTypes.count == 1 else {
            repo.sendAnalyticsEvent(.getLink(.shareMultipleNodes))
            return
        }

        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.shareFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.shareFolder))
        }
    }

    public func getLink(nodeTypes: [NodeTypeEntity]) {
        guard let nodeType = nodeTypes.first, nodeTypes.count == 1 else {
            repo.sendAnalyticsEvent(.getLink(.getLinkMultipleNodes))
            return
        }

        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.getLinkForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.getLinkForFolder))
        }
    }

    public func proFeatureSeePlans(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.proFeaturesSeePlansFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.proFeaturesSeePlansFolder))
        }
    }

    public func proFeatureNotNow(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.proFeaturesNotNowFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.proFeaturesNotNowFolder))
        }
    }

    public func encrypt(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.encryptFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.encryptFolder))
        }
    }
}
