
import SwiftUI

struct NetworkIsNotConnectedView: View {
    var body: some View {
        if #available(iOS 14.0, *) {
            Text(Strings.Localizable.General.noIntenerConnection)
                .font(.caption2.bold())
                .padding()
                .background(Color(red: 1.0, green: 0.83, blue: 0.16, opacity: 0.22))
        } else {
            Text(Strings.Localizable.General.noIntenerConnection)
                .font(.caption.bold())
                .padding()
                .background(Color(red: 1.0, green: 0.83, blue: 0.16, opacity: 0.22))
        }
    }
}
