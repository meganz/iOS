import SwiftUI

public struct UnreadCountView: View {
    private let isUnreadCountClipShapeCircle: Bool
    private let unreadCountString: String
    
    public init(
        isUnreadCountClipShapeCircle: Bool,
        unreadCountString: String
    ) {
        self.isUnreadCountClipShapeCircle = isUnreadCountClipShapeCircle
        self.unreadCountString = unreadCountString
    }
    
    public var body: some View {
        if isUnreadCountClipShapeCircle {
            Text(unreadCountString)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(5)
                .background(Color.red)
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
                .background(Color.red)
                .clipShape(
                    Capsule()
                )
        }
    }
}
