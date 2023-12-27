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
                
                Text(Strings.Localizable.automaticallyBackupYourPhotosAndVideosToTheCloudDrive)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxHeight: .infinity)
            
            Button(action: action) {
                Text(Strings.Localizable.enable)
                    .font(.body.weight(.semibold))
                    .foregroundColor( MEGAAppColor.White._FFFFFF.color)
                    .frame(width: 288, height: 50)
                    .background(MEGAAppColor.Green._00A886.color)
                    .cornerRadius(8)
                    .shadow(color: MEGAAppColor.Black._000000.color.opacity(0.15), radius: 2, x: 0, y: 1)
                    .contentShape(Rectangle())
            }
        }
        .padding(.bottom, 32)
    }
}

struct EnableCameraUploadsEmptyView_Preview: PreviewProvider {
    static var previews: some View {
        EnableCameraUploadsEmptyView { }
        
        EnableCameraUploadsEmptyView { }
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
