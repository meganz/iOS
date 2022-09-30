import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SlideShowOptionViewModel
    let preference: SlideShowViewModelPreferenceProtocol
    let router: SlideShowOptionContentRouting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            navigationBar
            Divider()
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.cellViewModels, id: \.self.id) { cellViewModel in
                    router.slideShowOptionCell(for: cellViewModel)
                        .onTapGesture {
                            viewModel.didSelectCell(cellViewModel)
                        }
                }
            }
            
            if viewModel.currentConfiguration.includeSubfolders {
                Text(viewModel.footerNote)
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .padding(.top, 6)
                    .padding(.leading)
            }
            
            Spacer().layoutPriority(1)
        }
        .sheet(isPresented: $viewModel.shouldShowDetail, content: {
            router.slideShowOptionDetailView(for: viewModel.selectedCell, isShowing: $viewModel.shouldShowDetail)
        })
        .listStyle(.plain)
        .navigationViewStyle(.stack)
    }
    
    var navBarButton: some View {
        Button {
            preference.restart(withConfig: viewModel.configuration())
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text(viewModel.doneButtonTitle)
                .font(.body)
                .foregroundColor(.primary.opacity(0.8))
        }
        .contentShape(Rectangle())
    }
    
    var navigationBar: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Text(viewModel.navigationTitle)
                .font(.headline)
                .padding(.vertical, 26)
        }
        .overlay(
            HStack {
                Spacer()
                navBarButton
            }.padding()
        )
    }
}
