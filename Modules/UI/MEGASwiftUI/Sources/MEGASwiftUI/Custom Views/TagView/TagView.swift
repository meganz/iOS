import MEGADesignToken
import SwiftUI

public struct TagView: View {
    let tagName: String
    let tagColor: Color
    let tagTextColor: Color
    let cornerRadius: CGFloat
    let paddingInsets: EdgeInsets
    let font: Font
    
    public init(
        tagName: String,
        tagColor: Color,
        tagTextColor: Color,
        cornerRadius: CGFloat = 8,
        paddingInsets: EdgeInsets = EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8),
        font: Font = .caption2.bold()
    ) {
        self.tagName = tagName
        self.tagColor = tagColor
        self.tagTextColor = tagTextColor
        self.cornerRadius = cornerRadius
        self.paddingInsets = paddingInsets
        self.font = font
    }
    
    public var body: some View {
        Text(tagName)
            .font(font)
            .foregroundStyle(tagTextColor)
            .tagStyle(backgroundColor: tagColor, cornerRadius: cornerRadius, paddingInsets: paddingInsets)
    }
}

public extension View {
    func tagStyle(
        backgroundColor: Color,
        cornerRadius: CGFloat = TokenSpacing._3,
        paddingInsets: EdgeInsets = EdgeInsets(
            top: TokenSpacing._2,
            leading: TokenSpacing._3,
            bottom: TokenSpacing._2,
            trailing: TokenSpacing._3
        )
    ) -> some View {
        modifier(TagStyleModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius, paddingInsets: paddingInsets))
    }
}

private struct TagStyleModifier: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let paddingInsets: EdgeInsets

    func body(content: Content) -> some View {
        content
            .padding(paddingInsets)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
    }
}
