import SwiftUI

struct DeviceCenterItemView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            Image(viewModel.assets.iconName)
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                HStack(spacing: 4) {
                    if viewModel.shouldShowBackupPercentage {
                        Text(viewModel.backupPercentage)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(viewModel.assets.backupStatus.color))
                            .clipShape(Capsule())
                    } else {
                        Image(viewModel.assets.backupStatus.iconName)
                            .renderingMode(.template)
                            .foregroundColor(Color(viewModel.assets.backupStatus.color))
                            .frame(width: 12, height: 12)
                    }
                    Text(viewModel.assets.backupStatus.title)
                        .font(.caption)
                        .foregroundColor(Color(viewModel.assets.backupStatus.color))
                    Spacer()
                }
            }
            Spacer()
            Button {
                viewModel.handleMainActionButtonPressed()
            } label: {
                Image(viewModel.mainActionIconName)
                    .renderingMode(.template)
                    .foregroundColor(.gray)
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
    }
}
