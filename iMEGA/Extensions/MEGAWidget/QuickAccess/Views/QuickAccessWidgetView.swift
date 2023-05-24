
import SwiftUI

struct QuickAccessWidgetView: View {
    var entry: QuickAccessWidgetEntry
    
    func headerView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                headerEntry()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("SecondaryBackground"))
            
            Divider()
                .background(Color.black)
                .opacity(0.3)
        }
    }
    
    @ViewBuilder
    private func headerEntry() -> some View {
        if entry.value.status == .noSession {
            Image(Asset.Images.Logo.megaLogoGrayscale.name)
                .resizable()
                .frame(width: 31, height: 28, alignment: .leading)
                .padding()
        } else {
            Text(entry.section)
                .font(.system(size: 17, weight: .bold, design: .default))
                .foregroundColor(Color(UIColor.label))
                .padding(.leading, 24)
        }
    }
    
    func detailView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.value.items.isEmpty {
                switch entry.link {
                case SectionDetail.recents.link:
                    emptyView(Asset.Images.EmptyStates.recentsEmptyState.name, Strings.Localizable.noRecentActivity)
                case SectionDetail.favourites.link:
                    emptyView(Asset.Images.EmptyStates.favouritesEmptyState.name, Strings.Localizable.noFavourites)
                default:
                    emptyView(Asset.Images.EmptyStates.offlineEmptyState.name, Strings.Localizable.offlineEmptyStateTitle)
                }
            } else {
                GridView(items: entry.value.items)
                    .padding([.top, .leading, .trailing], 8)
                Spacer()
                if entry.value.items.count == 8 {
                    HStack {
                        Spacer()
                        Text(Strings.Localizable.viewMore)
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .opacity(0.2)
                        Spacer()
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    func emptyView(_ emptyImage: String, _ emptyDescription: String) -> some View {
        VStack {
            Spacer()
            Image(emptyImage)
            Spacer()
            HStack {
                Spacer()
                Text(emptyDescription)
                    .font(.system(size: 18, weight: .regular, design: .default))
                Spacer()
            }
            Spacer()
        }
    }
    
    func errorView() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Error")
                    .font(.system(size: 18, weight: .regular, design: .default))
                Spacer()
            }
            Spacer()
        }
    }
    
    func noSessionView() -> some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                Text(Strings.Localizable.login)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(Color("#00A886"))
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("BasicButton"))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.15), radius: 8)
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    func connectingView() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(Strings.Localizable.loading)
                    .font(.system(size: 20, weight: .medium, design: .default))
                Spacer()
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func viewBuilder() -> some View {
        switch entry.value.status {
        case .connected:
            detailView()
        case .error:
            errorView()
        case .noSession:
            noSessionView()
        default:
            connectingView()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                headerView()
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.16)
                viewBuilder()
            }
            .background(Color(UIColor.systemBackground))
            .widgetURL(URL(string: entry.link))
        }
    }
}
