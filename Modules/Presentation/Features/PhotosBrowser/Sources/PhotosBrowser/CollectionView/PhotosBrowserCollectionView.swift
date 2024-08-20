import SwiftUI

struct PhotosBrowserCollectionView: View {
    @StateObject var viewModel: PhotosBrowserCollectionViewModel
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotosBrowserCollectionViewRepresenter(viewModel: viewModel)
        }
    }
}
