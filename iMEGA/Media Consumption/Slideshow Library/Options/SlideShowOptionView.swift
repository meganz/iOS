import SwiftUI

@available(iOS 14.0, *)
struct SlideShowOptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SlideShowOptionViewModel
    let router: SlideShowOptionContentRouting
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.cellViewModels, id: \.self.id) { cellViewModel in
                        router.slideShowOptionCell(for: cellViewModel)
                            .onTapGesture {
                                viewModel.didSelectCell(cellViewModel)
                            }
                    }
                }
                Text(viewModel.footerNote)
                    .foregroundColor(.secondary)
                    .font(.caption2)
                    .padding(.top, 6)
                    .padding(.leading)
                Spacer()
            }
            .sheet(isPresented: $viewModel.shouldShowDetail, content: {
                router.slideShowOptionDetailView(for: viewModel.selectedCell, isShowing: $viewModel.shouldShowDetail)
            })
            .listStyle(.plain)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: EmptyView(), trailing: navBarButton)
        }
        .navigationViewStyle(.stack)
    }
    
    var navBarButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text(viewModel.doneButtonTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : Color(Colors.General.Black._161616.color))
        }
    }
}
