import SwiftUI

struct DeviceCenterItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DeviceCenterItemViewModel
    @Binding var selectedViewModel: DeviceCenterItemViewModel?
    
    var body: some View {
        HStack {
            if let iconName = viewModel.iconName {
                Image(iconName)
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                HStack(spacing: 4) {
                    if viewModel.shouldShowBackupPercentage {
                        Text(viewModel.backupPercentage)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(viewModel.statusColorName))
                            .clipShape(Capsule())
                    } else {
                        if let statusIcon = viewModel.statusIconName {
                            Image(statusIcon)
                                .renderingMode(.template)
                                .foregroundColor(Color(viewModel.statusColorName))
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text(viewModel.statusTitle)
                        .font(.caption)
                        .foregroundColor(Color(viewModel.statusColorName))
                    Spacer()
                }
            }
            Spacer()
            Button {
                selectedViewModel = viewModel
            } label: {
                Image("moreList")
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
