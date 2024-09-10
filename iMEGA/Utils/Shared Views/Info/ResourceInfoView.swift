import DeviceCenter
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ResourceInfoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ResourceInfoViewModel
    
    private var backgroundColor: Color {
        isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : .clear
    }
    
    var body: some View {
        VStack(spacing: 0) {
            customNavigationBar
            
            List {
                VStack(alignment: .center) {
                    Spacer()
                    Image(viewModel.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    Spacer()
                }
                .frame(height: 156)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(backgroundColor)
                
                Text(viewModel.title)
                    .font(.callout)
                    .bold()
                    .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                    .padding(.vertical, 2)
                    .listRowBackground(backgroundColor)
                
                Section(header: Text(Strings.Localizable.details)) {
                    DetailRow(
                        title: Strings.Localizable.totalSize,
                        detail: viewModel.totalSize,
                        backgroundColor: backgroundColor
                    )
                    DetailRow(
                        title: Strings.Localizable.contains,
                        detail: viewModel.contentDescription,
                        backgroundColor: backgroundColor
                    )
                    if viewModel.formattedDate.isNotEmpty {
                        DetailRow(
                            title: Strings.Localizable.added,
                            detail: viewModel.formattedDate,
                            backgroundColor: backgroundColor
                        )
                    }
                }
            }
            .listStyle(.grouped)
        }
        .background()
    }
    
    private var customNavigationBar: some View {
        ZStack {
            Text(Strings.Localizable.info)
                .font(.headline)
                .bold()
                .foregroundColor(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
            
            HStack {
                Spacer()
                Button {
                    viewModel.dismiss()
                } label: {
                    Text(Strings.Localizable.close)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color(UIColor.label))
                }
            }
        }
        .padding()
        .background(isDesignTokenEnabled ?
                    TokenColors.Background.surface1.swiftUI :
                        colorScheme == .dark ? Color(UIColor(red: 0.173, green: 0.173, blue: 0.18, alpha: 1.0)) :
                        Color(UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0))
        )
    }
}

struct DetailRow: View {
    let title: String
    let detail: String
    let backgroundColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : UIColor.secondaryLabel.swiftUI
                )
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.label.swiftUI
                )
        }
        .listRowBackground(backgroundColor)
    }
}

#Preview {
    let dateFormatter: DateFormatterClosure = { date in
        DateFormatter.dateMediumTimeShort().localisedString(from: date)
    }
    
    let infoModel = ResourceInfoModel(
        icon: "pc-mac",
        name: "MEGA Mac",
        counter: ResourceCounter(
            files: 15,
            folders: 12
        ),
        totalSize: UInt64(5000000),
        added: Date(),
        formatDateClosure: dateFormatter
    )
    
    return ResourceInfoView(
        viewModel:
            ResourceInfoViewModel(
                infoModel: infoModel,
                router:
                    ResourceInfoViewRouter(
                        presenter: UIViewController(),
                        infoModel: infoModel
                    )
            )
    )
}
