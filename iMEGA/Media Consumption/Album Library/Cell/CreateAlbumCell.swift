import MEGAL10n
import SwiftUI

struct CreateAlbumCell: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: CreateAlbumCellViewModel
    
    private var plusIconColor: Color {
        colorScheme == .light ? MEGAAppColor.Gray._515151.color : MEGAAppColor.White._FCFCFC.color
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .center) {
                MEGAAppColor.Gray._EBEBEB.color
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(6)
                
                Image(systemName: "plus")
                    .font(.system(size: viewModel.plusIconSize))
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
    }
}
