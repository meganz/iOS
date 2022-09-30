import SwiftUI

@available(iOS 14.0, *)
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
                    .font(.title3)
                
                Spacer()
                if viewModel.isSelcted {
                    Image(uiImage: Asset.Images.Generic.turquoiseCheckmark.image)
                        .scaledToFit()
                        .foregroundColor(.green)
                        .padding(.trailing, 14)
                }
            }
            .contentShape(Rectangle())
            Divider()
        }
    }
}
