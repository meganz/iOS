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
                    .foregroundColor(Color(Colors.General.Green._00A886.name))
            }
        )
    }
}
