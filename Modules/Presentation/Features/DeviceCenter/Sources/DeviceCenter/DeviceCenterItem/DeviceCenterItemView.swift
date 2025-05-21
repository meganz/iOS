import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import SwiftUI

struct DeviceCenterItemView: View {
    @ObservedObject var viewModel: DeviceCenterItemViewModel
    @Binding var selectedViewModel: DeviceCenterItemViewModel?
        
    init(viewModel: DeviceCenterItemViewModel, selectedViewModel: Binding<DeviceCenterItemViewModel?>) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._selectedViewModel = selectedViewModel
        self.viewModel.updateSelectedViewModel = { [selectedViewModel] vm in
            selectedViewModel.wrappedValue = vm
        }
    }
    
    var body: some View {
        HStack {
            MEGAAssets.Image.image(named: viewModel.assets.iconName)
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                HStack(spacing: 4) {
                    if viewModel.shouldShowBackupPercentage {
                        Text(viewModel.backupPercentage)
                            .font(.caption)
                            .foregroundStyle(TokenColors.Text.onColor.swiftUI)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(viewModel.assets.statusAssets.color))
                            .clipShape(Capsule())
                    } else {
                        MEGAAssets.Image.image(named: viewModel.assets.statusAssets.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .foregroundStyle(Color(viewModel.assets.statusAssets.color))
                            .frame(width: 12, height: 12)
                    }
                    Text(viewModel.assets.statusAssets.title)
                        .font(.caption)
                        .foregroundStyle(Color(viewModel.assets.statusAssets.color))
                    Spacer()
                }
            }
            Spacer()
            Button {
                viewModel.handleMainActionButtonPressed()
            } label: {
                MEGAAssets.Image.image(named: viewModel.mainActionIconName)
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .frame(width: 60, height: 60)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.showDetail()
        }
        .background()
        .frame(minHeight: 60)
    }
}
