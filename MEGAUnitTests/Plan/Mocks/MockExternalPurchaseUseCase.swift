// Copyright © 2025 MEGA Limited. All rights reserved.

import Foundation
import MEGAStoreKit

public final class MockExternalPurchaseUseCase: ExternalPurchaseUseCaseProtocol, @unchecked Sendable {
    public enum Action: Equatable {
        case shouldProvideExternalPurchase
        case externalPurchaseLink(path: String, sourceApp: String?, months: Int?)
    }

    public var actions: [Action] = []
    public var _shouldProvideExternalPurchase: Bool
    public var _externalPurchaseLink: Result<URL, any Error>

    public init(
        shouldProvideExternalPurchase: Bool = false,
        externalPurchaseLink: Result<URL, any Error> = .success(URL(string: "https://example.com")!)
    ) {
        _shouldProvideExternalPurchase = shouldProvideExternalPurchase
        _externalPurchaseLink = externalPurchaseLink
    }

    public func shouldProvideExternalPurchase() async -> Bool {
        actions.append(.shouldProvideExternalPurchase)
        return _shouldProvideExternalPurchase
    }

    public func externalPurchaseLink(path: String, sourceApp: String?, months: Int?) async throws -> URL {
        actions.append(.externalPurchaseLink(path: path, sourceApp: sourceApp, months: months))
        return try _externalPurchaseLink.get()
    }
}
