import MEGADomain
import UIKit

@MainActor
public protocol PhotoSearchResultRouterProtocol: Sendable {
    func didTapMoreAction(on node: HandleEntity, button: UIButton)
}
