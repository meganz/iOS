import SwiftUI

struct CreateAlbumCell: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: CreateAlbumCellViewModel
    
    private var plusIconColor: Color {
        colorScheme == .light ? Color(Colors.General.Gray._515151.color) : Color(Colors.General.White.fcfcfc.color)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack (alignment: .center) {
                Color(Colors.General.Gray.ebebeb.color)
                    .aspectRatio(contentMode: .fill)
                    .cornerRadius(6)
                
                Image(systemName: "plus")
                    .font(.system(size: viewModel.plusIconSize))
                    .foregroundColor(plusIconColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(Strings.Localizable.CameraUploads.Albums.CreateAlbum.title)
                    .font(.system(size: 13.0))
                Text("")
                    .font(.system(size: 12.0))
            }
        }
    }
}
