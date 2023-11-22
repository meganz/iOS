import SwiftUI

public struct ColorSchemeDesiredColor: ShapeStyle {
    
    let lightMode: Color
    let darkMode: Color
    
    public init(lightMode: Color, darkMode: Color) {
        self.lightMode = lightMode
        self.darkMode = darkMode
    }
    
    public func resolve(in environment: EnvironmentValues) -> Color {
        switch environment.colorScheme {
        case .light:
            return lightMode
        case .dark:
            return darkMode
        @unknown default:
            return lightMode
        }
    }
}
