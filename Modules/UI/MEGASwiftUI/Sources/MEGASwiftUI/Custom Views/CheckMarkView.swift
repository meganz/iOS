import MEGADesignToken
import SwiftUI

public struct CheckMarkView: View {
    let markedSelected: Bool
    let foregroundColor: Color
    let showBorder: Bool
    let borderColor: Color
    
    var iconForegroundColor: Color?
    
    /// Legacy  initializer
    /// - Parameters:
    ///   - markedSelected: a boolean indicates selected state
    ///   - foregroundColor: view background color
    ///   - showBorder: a boolean indicates border
    ///   - borderColor: a border color
    public init(markedSelected: Bool,
                foregroundColor: Color,
                showBorder: Bool = true,
                borderColor: Color = Color.white) {
        self.markedSelected = markedSelected
        self.foregroundColor = foregroundColor
        self.showBorder = showBorder
        self.borderColor = borderColor
    }
    
    /// Semantic Design token initializer
    /// - Parameters:
    ///   - markedSelected: a boolean indicates selected state
    ///   - iconForegroundColor: checkmark icon color
    ///   - foregroundColor: view background color
    ///   - showBorder: a boolean indicates border
    ///   - borderColor: a border color
    public init(markedSelected: Bool,
                iconForegroundColor: Color,
                foregroundColor: Color,
                showBorder: Bool = true,
                borderColor: Color) {
        self.init(
            markedSelected: markedSelected,
            foregroundColor: foregroundColor,
            showBorder: showBorder,
            borderColor: borderColor
        )
        
        self.iconForegroundColor = iconForegroundColor
    }
    
    private var imageName: String {
        markedSelected ? "checkmark.circle.fill" : "circle"
    }
    
    private var backgroundView: some View {
        markedSelected && showBorder ? Color.white.mask(Circle()) : nil
    }
    
    public var body: some View {
        if isDesignTokenEnabled {
            designTokenCheckMarkView
        } else {
            Image(systemName: imageName)
                .font(.system(size: 23))
                .foregroundStyle(foregroundColor)
                .background(backgroundView)
        }
    }
    
    private var designTokenCheckMarkView: some View {
        ZStack {
            designTokenCheckMarkCircleBackgroundView
            
            if let iconForegroundColor, markedSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(iconForegroundColor)
                    .font(.system(size: 12))
            }
        }
    }
    
    @ViewBuilder
    private var designTokenCheckMarkCircleBackgroundView: some View {
        if #available(iOS 17.0, *) {
            Circle()
                .fill(foregroundColor)
                .stroke(borderColor, lineWidth: markedSelected ? 0 : 1)
                .frame(width: 22, height: 22)
        } else {
            Circle()
                .fill(foregroundColor)
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(borderColor, lineWidth: markedSelected ? 0 : 1))
        }
    }
}

// MARK: - Preview

#Preview {
    Group {
        /// Example legacy
        CheckMarkView(markedSelected: true, foregroundColor: Color.green)
    }
}

#Preview {
    /// Example semantic color token
    Group {
        CheckMarkView(
            markedSelected: false,
            iconForegroundColor: TokenColors.Icon.inverseAccent.swiftUI,
            foregroundColor: TokenColors.Border.strong.swiftUI,
            borderColor: TokenColors.Border.strong.swiftUI
        )
        
        CheckMarkView(
            markedSelected: true,
            iconForegroundColor: TokenColors.Icon.inverseAccent.swiftUI,
            foregroundColor: TokenColors.Components.selectionControl.swiftUI,
            borderColor: Color.clear
        )
    }
}
