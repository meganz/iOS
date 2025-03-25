import DeviceCenter
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ResourceInfoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: ResourceInfoViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            customNavigationBar
            
            List {
                VStack(alignment: .center) {
                    Spacer()
                    viewModel.icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    Spacer()
                }
                .frame(height: 156)
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowBackground(TokenColors.Background.page.swiftUI)
                
                Text(viewModel.title)
                    .font(.callout)
                    .bold()
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .padding(.vertical, 2)
                    .listRowBackground(TokenColors.Background.page.swiftUI)
                
                Section(header: Text(Strings.Localizable.details)) {
                    DetailRow(
                        title: Strings.Localizable.totalSize,
                        detail: viewModel.totalSize,
                        backgroundColor: TokenColors.Background.page.swiftUI
                    )
                    DetailRow(
                        title: Strings.Localizable.contains,
                        detail: viewModel.contentDescription,
                        backgroundColor: TokenColors.Background.page.swiftUI
                    )
                    if viewModel.formattedDate.isNotEmpty {
                        DetailRow(
                            title: Strings.Localizable.added,
                            detail: viewModel.formattedDate,
                            backgroundColor: TokenColors.Background.page.swiftUI
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
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            
            HStack {
                Spacer()
                Button {
                    viewModel.dismiss()
                } label: {
                    Text(Strings.Localizable.close)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                }
            }
        }
        .padding()
        .background(TokenColors.Background.surface1.swiftUI)
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
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
        .listRowBackground(backgroundColor)
    }
}

#Preview {
    let dateFormatter: DateFormatterClosure = { date in
        DateFormatter.dateMediumTimeShort().localisedString(from: date)
    }
    
    let infoModel = ResourceInfoModel(
        icon: Image(.blue),
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
