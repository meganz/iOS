import SwiftUI

public struct UnreadCountBadgeView: View {
    private let unreadCountString: String
    private let backgroundColor: Color
    
    public init(
        unreadCountString: String,
        backgroundColor: Color
    ) {
        self.unreadCountString = unreadCountString
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        if unreadCountString.count <= 1 {
            Text(unreadCountString)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(5)
                .background(backgroundColor)
                .clipShape(
                    Circle()
                )
        } else {
            Text(unreadCountString)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(
                    EdgeInsets(top: 1, leading: 5, bottom: 1, trailing: 5)
                )
                .background(backgroundColor)
                .clipShape(
                    Capsule()
                )
        }
    }
}
