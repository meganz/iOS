import UIKit

/// represents a decoration element that can be placed in the view representing a node
/// it can specify a property of a result and be rendered as icon, text or a spacer element in swiftUI
/// support dynamic positioning (single property can be differently placed depending on the layout in which the result view is shown) via
/// placement closure
public struct ResultProperty: Identifiable, Equatable, Sendable {
    
    public static func == (lhs: ResultProperty, rhs: ResultProperty) -> Bool {
        guard
            lhs.id == rhs.id,
            lhs.content == rhs.content
        else {
            return false
        }
        return true
    }
    
    public typealias Id = String
    
    public enum Content: Equatable, Sendable {
        case icon(image: UIImage, scalable: Bool)
        case text(String)
        case spacer
    }
    
    public let id: Id
    public let content: Content
    /// if any result property has this enabled, title will be vibrantly rendered, used now for taken down nodes
    /// for taken down noes in MEGA, it means a red title text label
    public let vibrancyEnabled: Bool
    public let placement: @Sendable (ResultCellLayout) -> PropertyPlacement
    
    public init(
        id: Id,
        content: Content,
        vibrancyEnabled: Bool,
        placement: @Sendable @escaping (ResultCellLayout) -> PropertyPlacement
    ) {
        self.id = id
        self.content = content
        self.vibrancyEnabled = vibrancyEnabled
        self.placement = placement
    }
}
