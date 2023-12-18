import MEGAL10n
import SwiftUI

struct CreateAlbumCell: View {
    let onTapHandler: (() -> Void)

    @Environment(\.colorScheme) private var colorScheme
    @State private var orientation = UIDevice.current.orientation

    private var plusIconColor: Color {
        colorScheme == .light ? MEGAAppColor.Gray._515151.color : MEGAAppColor.White._FCFCFC.color
    }
    
    var body: some View {
        Button(action: onTapHandler, label: content)
            .buttonStyle(.plain)
    }
    
    func content() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                MEGAAppColor.Gray._EBEBEB.color
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(6)
                
                Image(systemName: "plus")
                    .font(.system(size: iconSize))
                    .foregroundColor(plusIconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Localizable.CameraUploads.Albums.CreateAlbum.title)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .font(.caption)
                Text(" ")
                    .font(.footnote)
            }
        }
        .onOrientationChanged { orientation = $0 }
    }
    
    private var iconSize: CGFloat {
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            UIDevice.current.iPad ? 35 : 25
        default:
            UIDevice.current.iPad ? 25 : 20
        }
    }
}
