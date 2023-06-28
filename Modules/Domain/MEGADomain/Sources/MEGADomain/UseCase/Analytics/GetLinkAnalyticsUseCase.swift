import Foundation

public protocol GetLinkAnalyticsUseCaseProtocol {
    func sendDecriptionKey(nodeType: NodeTypeEntity)
    func setExpiryDate(nodeType: NodeTypeEntity)
    func setPassword(nodeType: NodeTypeEntity)
    func confirmPassword(nodeType: NodeTypeEntity)
    func resetPassword(nodeType: NodeTypeEntity)
    func removePassword(nodeType: NodeTypeEntity)
    func shareLink(nodeTypes: [NodeTypeEntity])
    func getLink(nodeTypes: [NodeTypeEntity])
    func proFeatureSeePlans(nodeType: NodeTypeEntity)
    func proFeatureNotNow(nodeType: NodeTypeEntity)
}

public struct GetLinkAnalyticsUseCase<T: AnalyticsRepositoryProtocol>: GetLinkAnalyticsUseCaseProtocol {
    private let repo: T

    public init(repository: T) {
        repo = repository
    }

    public func sendDecriptionKey(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.sendDecriptionKeySeparateForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.sendDecriptionKeySeparateForFolder))
        }
    }

    public func setExpiryDate(nodeType: NodeTypeEntity) {
        if nodeType == .file {
            repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFile))
        } else if nodeType == .folder {
            repo.sendAnalyticsEvent(.getLink(.setExpiryDateForFolder))
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
            let hasFiles = nodeTypes.contains(where: { $0 == .file })
            let hasFolders = nodeTypes.contains(where: { $0 == .folder })

            if hasFiles && hasFolders {
                repo.sendAnalyticsEvent(.getLink(.shareFilesAndFolders))
            } else if hasFiles {
                repo.sendAnalyticsEvent(.getLink(.shareFiles))
            } else if hasFolders {
                repo.sendAnalyticsEvent(.getLink(.shareFolders))
            }

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
            let hasFiles = nodeTypes.contains(where: { $0 == .file })
            let hasFolders = nodeTypes.contains(where: { $0 == .folder })

            if hasFiles && hasFolders {
                repo.sendAnalyticsEvent(.getLink(.getLinkForFilesAndFolders))
            } else if hasFiles {
                repo.sendAnalyticsEvent(.getLink(.getLinkForFiles))
            } else if hasFolders {
                repo.sendAnalyticsEvent(.getLink(.getLinkForFolders))
            }

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
}
