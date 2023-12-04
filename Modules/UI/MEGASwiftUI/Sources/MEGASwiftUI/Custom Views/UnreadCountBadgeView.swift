import SwiftUI

public struct UnreadCountBadgeView: View {
    private let unreadCountString: String
    
    public init(
        unreadCountString: String
    ) {
        self.unreadCountString = unreadCountString
    }
    
    public var body: some View {
        if unreadCountString.count <= 1 {
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
