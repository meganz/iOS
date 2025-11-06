import SwiftUI

struct PhotosBrowserCollectionView: View {
    @ObservedObject var viewModel: PhotosBrowserCollectionViewModel
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            PhotosBrowserCollectionViewRepresenter(viewModel: viewModel)
        }
    }
}
