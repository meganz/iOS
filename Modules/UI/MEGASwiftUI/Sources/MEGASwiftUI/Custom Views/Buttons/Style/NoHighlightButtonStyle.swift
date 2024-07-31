import SwiftUI

/// A button style that does not have any highlight effect during button tap.
public struct NoHighlightButtonStyle: ButtonStyle {
    
    public init () {}
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}
