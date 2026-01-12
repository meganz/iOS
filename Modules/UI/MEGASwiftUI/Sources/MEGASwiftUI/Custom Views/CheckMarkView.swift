import MEGADesignToken
import SwiftUI

public struct CheckMarkView: View {
    let markedSelected: Bool
    let foregroundColor: Color
    let showBorder: Bool
    let borderColor: Color
    let isMediaRevamp: Bool
    
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
                borderColor: Color = Color.white,
                isMediaRevamp: Bool = false) {
        self.markedSelected = markedSelected
        self.foregroundColor = foregroundColor
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.isMediaRevamp = isMediaRevamp
    }
    
    private var imageName: String {
        markedSelected ? "checkmark.circle.fill" : "circle"
    }
    
    public var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 23))
            .foregroundStyle(isMediaRevamp ? Color.white : foregroundColor, foregroundColor)
            .if(!isMediaRevamp && markedSelected && showBorder) { view in
                view.background(Color.white.mask(Circle()))
            }
            .opacity(isMediaRevamp && !markedSelected ? 0 : 1)
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
