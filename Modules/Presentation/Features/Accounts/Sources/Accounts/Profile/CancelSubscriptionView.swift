import MEGADesignToken
import MEGAL10n
import SwiftUI

public struct CancelSubscriptionView: View {
    private var textColor: UIColor
    
    public init(textColor: UIColor) {
        self.textColor = textColor
    }
    
    public var body: some View {
        Text(Strings.Localizable.Account.Subscription.Cancel.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(textColor.swiftUI)
            .padding(.vertical, 10)
    }
}

#Preview {
    CancelSubscriptionView(textColor: .red)
}
