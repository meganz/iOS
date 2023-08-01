import Foundation

public struct AppDistributionReleaseEntity: Sendable, Equatable {
    public let displayVersion: String
    public let buildVersion: String
    public let downloadURL: URL
    
    public init(displayVersion: String, buildVersion: String, downloadURL: URL) {
        self.displayVersion = displayVersion
        self.buildVersion = buildVersion
        self.downloadURL = downloadURL
    }
}
