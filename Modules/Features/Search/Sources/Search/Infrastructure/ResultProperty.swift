import SwiftUI
import UIKit

/// represents a decoration element that can be placed in the view representing a node
/// it can specify a property of a result and be rendered as icon, text or a spacer element in swiftUI
/// support dynamic positioning (single property can be differently placed depending on the layout in which the result view is shown) via
/// placement closure
public struct ResultProperty: Identifiable, Equatable, Comparable, Sendable {
    // Comparable implementation is used for placement of properties within a single
    // location (line) to decide which one should go first, we place
    // vibrant properties as first in the line
    public static func < (lhs: ResultProperty, rhs: ResultProperty) -> Bool {
        
        switch (lhs.vibrancyEnabled, rhs.vibrancyEnabled) {
        case (true, true):
            return true
        case (true, false):
            return true
        case (false, true):
            return false
        case (false, false):
            return false
        }
    }
    
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
    
    public enum Content: Hashable, Sendable {
        public struct LayoutConfiguration: Sendable, Hashable {
            let scalable: Bool
            let size: CGFloat
            let horizontalPadding: CGFloat
            let renderingMode: Image.TemplateRenderingMode

            public init(scalable: Bool, size: CGFloat, horizontalPadding: CGFloat = 0, renderingMode: Image.TemplateRenderingMode = .template) {
                self.scalable = scalable
                self.size = size
                self.horizontalPadding = horizontalPadding
                self.renderingMode = renderingMode
            }
        }
        case icon(image: UIImage, layoutConfig: LayoutConfiguration)
        case text(String)
        case spacer
    }
    
    public let id: Id
    public let content: Content
    /// if any result property has this enabled, title will be vibrantly rendered, used now for taken down nodes
    /// for taken down noes in MEGA, it means a red title text label
    /// additionally, vibrancy enabled result properties, will be shown a the first positions (leading) in the requested placement [FM-1405]
    /// if there are multiple ones, they are not sorted further, and just keep ordering on the containing collection
    public let vibrancyEnabled: Bool
    public let accessibilityLabel: String
    public let placement: @Sendable (ResultCellLayout) -> PropertyPlacement
    
    public init(
        id: Id,
        content: Content,
        vibrancyEnabled: Bool,
        accessibilityLabel: String = "",
        placement: @Sendable @escaping (ResultCellLayout) -> PropertyPlacement
    ) {
        self.id = id
        self.content = content
        self.vibrancyEnabled = vibrancyEnabled
        self.accessibilityLabel = accessibilityLabel
        self.placement = placement
    }
}
