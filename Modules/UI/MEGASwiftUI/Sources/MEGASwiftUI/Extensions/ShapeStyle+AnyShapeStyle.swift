import SwiftUI

public extension ShapeStyle {
    func toAnyShapeStyle() -> AnyShapeStyle {
        AnyShapeStyle(self)
    }
}
