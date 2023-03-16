import SwiftUI

struct AlbumContentPickerView: View {
    @StateObject var viewModel: AlbumContentPickerViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ZStack {
            Color(backGroundColor)
            VStack(spacing: 0) {
                navigationBar
                
                PhotoLibraryContentView(
                    viewModel: viewModel.photoLibraryContentViewModel,
                    router: PhotoLibraryContentViewRouter(),
                    onFilterUpdate: nil
                )
                
                Spacer()
                footer
            }
        }
        .onChange(of: viewModel.isDismiss, perform: { newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        })
        .edgesIgnoringSafeArea(.vertical)
    }
    
    var navigationBar: some View {
        VStack(spacing: 0) {
            Text(viewModel.navigationTitle)
                .lineLimit(1)
                .font(.footnote)
                .foregroundColor(.primary)
                .padding(.bottom, 14)
                .padding(.top, 18)
                .padding(.horizontal, 30)
            
            HStack {
                Button {
                    viewModel.onCancel()
                } label: {
                    Text(Strings.Localizable.cancel)
                        .font(.body)
                        .foregroundColor(textColor)
                }.padding(10)
                
                Text(viewModel.photoSourceLocationNavigationTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                
                Button {
                    viewModel.onDone()
                } label: {
                    Text(Strings.Localizable.done)
                        .font(.body.bold())
                        .foregroundColor(textColor.opacity(viewModel.isDoneButtonDisabled ? 0.5 : 1))
                }.padding(10)
                .disabled(viewModel.isDoneButtonDisabled)
            }.padding(.bottom, 10)
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if !viewModel.shouldRemoveFilter {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.onFilter()
                    } label: {
                        Text(Strings.Localizable.filter)
                            .font(.body)
                            .foregroundColor(textColor)
                    }.padding(20)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var backGroundColor: UIColor {
        colorScheme == .dark ? UIColor.mnz_black1C1C1E() : UIColor.mnz_grayF7F7F7()
    }
    
    private var textColor: Color {
        colorScheme == .dark ? Color(UIColor.mnz_grayD1D1D1()) : Color(UIColor.mnz_gray515151())
    }
}
