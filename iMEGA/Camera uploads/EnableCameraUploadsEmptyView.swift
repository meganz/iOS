import MEGADesignToken
import MEGAL10n
import SwiftUI

struct EnableCameraUploadsEmptyView: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 10) {
                Image(.enableCameraUploadsPhotoLibraryEmpty)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200, maxHeight: 200)
                
                Text(Strings.Localizable.enableCameraUploadsButton)
                    .font(.headline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Text(Strings.Localizable.automaticallyBackupYourPhotosAndVideosToTheCloudDrive)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .frame(maxHeight: .infinity)
            
            Button(action: action) {
                Text(Strings.Localizable.enable)
                    .font(.body.weight(.semibold))
                    .foregroundColor(TokenColors.Text.inverse.swiftUI)
                    .frame(width: 288, height: 50)
                    .background(TokenColors.Button.primary.swiftUI)
                    .cornerRadius(8)
                    .shadow(color: .black000000.opacity(0.15), radius: 2, x: 0, y: 1)
                    .contentShape(Rectangle())
            }
        }
        .background()
        .padding(.bottom, 32)
    }
}

#Preview {
    EnableCameraUploadsEmptyView { }
}
