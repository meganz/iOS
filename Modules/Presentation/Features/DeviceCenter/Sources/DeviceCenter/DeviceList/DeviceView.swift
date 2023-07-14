import SwiftUI

struct DeviceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: DeviceViewModel
    
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
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                HStack(spacing: 4) {
                    if let statusIcon = viewModel.statusIconName {
                        Image(statusIcon)
                            .renderingMode(.template)
                            .foregroundColor(Color(viewModel.statusColorName))
                            .frame(width: 12, height: 12)
                    }
                    Text(viewModel.statusTitle)
                        .font(.caption)
                        .foregroundColor(Color(viewModel.statusColorName))
                    Spacer()
                }
            }
            Spacer()
            Button {
            } label: {
                Image("moreList")
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }.buttonStyle(.borderless)
        }
    }
}
