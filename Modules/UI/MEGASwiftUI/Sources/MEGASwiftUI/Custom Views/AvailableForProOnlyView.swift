import SwiftUI

public struct AvailableForProOnlyView: View {
    private let proOnlyText: String
    private let foregroundColor: Color
    private let borderColor: Color
    private let cornerRadius: CGFloat

    public init(proOnlyText: String, foregroundColor: Color, borderColor: Color, cornerRadius: CGFloat) {
        self.proOnlyText = proOnlyText
        self.foregroundColor = foregroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Text(proOnlyText)
            .foregroundStyle(foregroundColor)
            .font(.caption2)
            .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .border(borderColor)
            .cornerRadius(cornerRadius)
    }
}
