import MEGAL10n
import SwiftUI

struct NodeInfoVerifyAccountTableViewCell: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(
            action: onTap,
            label: {
                Text(Strings.Localizable.verifyCredentials)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color(UIColor.green00A886))
            }
        )
    }
}
