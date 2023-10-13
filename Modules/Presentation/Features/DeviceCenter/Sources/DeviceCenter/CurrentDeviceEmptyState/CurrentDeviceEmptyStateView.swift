import MEGAL10n
import SwiftUI

struct CurrentDeviceEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Image("folderEmptyState")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
            VStack(spacing: 10) {
                Text(Strings.Localizable.Device.Center.Current.Device.Empty.State.message)
                    .font(.body)
            }
            .padding([.horizontal], 40)
            Spacer()
            Button(action: action) {
                Text(Strings.Localizable.enableCameraUploadsButton)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .padding([.horizontal], 40)
            }
            .frame(height: 50)
            .background(colorScheme == .dark ? Color("00C29A") : Color("00A886"))
            .cornerRadius(8)
            Spacer().frame(height: 40)
        }
        .padding(.top, 40)
    }
}
