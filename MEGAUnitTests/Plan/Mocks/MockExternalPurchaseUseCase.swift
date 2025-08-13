// Copyright © 2025 MEGA Limited. All rights reserved.

import Foundation
import MEGAStoreKit
import MEGASwift

public final class MockExternalPurchaseUseCase: ExternalPurchaseUseCaseProtocol, @unchecked Sendable {
    public enum Action: Equatable {
        case shouldProvideExternalPurchase
        case externalPurchaseLink(domain: String, path: String, sourceApp: String?, months: Int?)
    }

    @Atomic public var actions: [Action] = []
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
        $actions.mutate { $0.append(.shouldProvideExternalPurchase) }
        return _shouldProvideExternalPurchase
    }

    public func externalPurchaseLink(
        domain: String,
        path: String,
        sourceApp: String?,
        months: Int?
    ) async throws -> URL {
        $actions.mutate {
            $0.append(.externalPurchaseLink(domain: domain, path: path, sourceApp: sourceApp, months: months))
        }
        return try _externalPurchaseLink.get()
    }
}
