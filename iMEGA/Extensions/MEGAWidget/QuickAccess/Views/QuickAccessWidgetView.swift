
import SwiftUI

struct QuickAccessWidgetView: View {
    var entry: QuickAccessWidgetEntry
        
    func headerView() -> some View {
        let headerView = VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
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
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("SecondaryBackground"))
            Divider()
                .background(Color.black)
                .opacity(0.3)
        }
        return AnyView(headerView)
    }
    
    func detailView() -> some View {
        let detailView = VStack(alignment: .leading, spacing: 0) {
            if entry.value.items.count == 0 {
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
                    HStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                        Spacer()
                        Text(Strings.Localizable.viewMore)
                            .font(.system(size: 10, weight: .medium, design: .default))
                            .opacity(0.2)
                        Spacer()
                    })
                    .padding(.bottom, 16)
                }
            }
        }
        return AnyView(detailView)
    }
    
    func emptyView(_ emptyImage: String, _ emptyDescription: String) -> some View {
        let view = VStack {
            Spacer()
            Image(emptyImage)
            Spacer()
            HStack (alignment: .center, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                Spacer()
                Text(emptyDescription)
                    .font(.system(size: 18, weight: .regular, design: .default))
                Spacer()
            })
            Spacer()
        }
    
        return AnyView(view)
    }
    
    func errorView() -> some View {
        let view = VStack {
            Spacer()
            HStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                Spacer()
                Text("Error")
                    .font(.system(size: 18, weight: .regular, design: .default))
                Spacer()
            })
            Spacer()
        }
    
        return AnyView(view)
    }
    
    func noSessionView() -> some View {
        let view = VStack {
            Spacer()
            HStack (alignment: .center, spacing: 0, content: {
                Spacer()
                Text(Strings.Localizable.login)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(Color("#00A886"))
                Spacer()
            })
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color("BasicButton"))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.15), radius: 8)
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    
        return AnyView(view)
    }
    
    func connectingView() -> some View {
        let view = VStack {
            Spacer()
            HStack (alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/, content: {
                Spacer()
                Text(Strings.Localizable.loading)
                    .font(.system(size: 20, weight: .medium, design: .default))
                Spacer()
            })
            Spacer()
        }
    
        return AnyView(view)
    }
    
    func viewBuilder() -> some View {
        let view: AnyView
        switch entry.value.status {
        case .connected:
            view = AnyView(detailView())
        case .error:
            view = AnyView(errorView())
        case .noSession:
            view = AnyView(noSessionView())
        default:
            view = AnyView(connectingView())
        }
        return view
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
