import MEGASwift
import MEGASwiftUI

@MainActor
package final class PromotionalBannerCache {
    static let shared = PromotionalBannerCache()

    private(set) var cachedViewModels = [PromotionalBannerViewModel]()

    private init() {}

    func update(with viewModels: [PromotionalBannerViewModel]) {
        cachedViewModels = viewModels
    }

    func removeBanner(withId id: Int) {
        cachedViewModels.removeAll { $0.input.id == id }
    }
}
