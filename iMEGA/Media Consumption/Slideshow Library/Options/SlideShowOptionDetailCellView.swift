import SwiftUI

struct SlideShowOptionDetailCellView: View {
    @ObservedObject var viewModel: SlideShowOptionDetailCellViewModel
    
    var body: some View {
        VStack {
            HStack {
                if let icon = viewModel.image {
                    Image(uiImage: icon.image)
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                
                Text(viewModel.title)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                
                Spacer()
                if viewModel.isSelcted {
                    Image(uiImage: Asset.Images.Generic.turquoiseCheckmark.image)
                        .foregroundColor(.green)
                        .padding(.trailing, 14)
                }
            }
            .contentShape(Rectangle())
            Divider()
        }
    }
}
