import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import SwiftUI

// will move this to MEGASwiftUI as part of [MEET-3647]
struct BannerView: View {
    
    struct Config {
        var copy: String
        var underline: Bool = false
        var theme: Theme
        var closeAction: (() -> Void)?
        var tapAction: (() -> Void)?
        
        static let empty: Config = .init(copy: "", theme: .light)
        
        struct Theme {
            var background: Color
            var foregroundUIColor: UIColor
            var foreground: Color
            var link: UIColor
            
            // Meetings Floating panel only support dark mode
            static let darkMeetingsFloatingPanel: Self = .init(
                background: TokenColors.Notifications.notificationWarning.swiftUI,
                foregroundUIColor: TokenColors.Text.primary,
                foreground: TokenColors.Text.primary.swiftUI,
                link: TokenColors.Text.primary
            )
            
            static let dark: Self = .init(
                background: TokenColors.Notifications.notificationWarning.swiftUI,
                foregroundUIColor: TokenColors.Text.primary,
                foreground: TokenColors.Text.primary.swiftUI,
                link: TokenColors.Link.primary
            )
            
            static let light: Self = .init(
                background: TokenColors.Background.page.swiftUI,
                foregroundUIColor: TokenColors.Text.primary,
                foreground: TokenColors.Text.primary.swiftUI,
                link: TokenColors.Link.primary
            )
        }
    }
    
    var config: Config
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            text
            Spacer()
            closeButton
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .background(config.theme.background)
        .onTapGesture {
            config.tapAction?()
        }
    }
    
    private var text: some View {
        TaggableText(
            config.copy,
            underline: config.underline,
            linkColor: config.theme.link
        )
        .foregroundColor(config.theme.foreground)
    }
    
    @ViewBuilder
    private var closeButton: some View {
        if let closeAction = config.closeAction {
            Button {
                withAnimation {
                    closeAction()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(config.theme.foreground)
                    .font(.system(size: 20))
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    VStack {
        BannerView(
            config: .init(
                copy: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title,
                underline: false,
                theme: .dark,
                closeAction: {
                })
        )
        .colorScheme(.light)
        
        BannerView(
            config: .init(
                copy: "Some interesting long copy with a [A]LINK[/A]",
                underline: true,
                theme: .light
            )
        )
        .colorScheme(.light)
        
        BannerView(
            config: .init(
                copy: "Nice long copy describing a situation [A]Link[/A]",
                underline: false,
                theme: .dark,
                closeAction: {
                })
        )
        .colorScheme(.dark)
        
        BannerView(
            config: .init(
                copy: "Some interesting long copy with a [A]LINK[/A]",
                underline: true,
                theme: .light
            )
        )
        .colorScheme(.dark)
        
        BannerView(
            config: .init(
                copy: "Nice long copy describing a situation [A]Link[/A]",
                underline: false,
                theme: .darkMeetingsFloatingPanel,
                closeAction: {
                })
        )
        .colorScheme(.dark)
        
        BannerView(
            config: .init(
                copy: "Some interesting long copy with a [A]LINK[/A]",
                underline: true,
                theme: .darkMeetingsFloatingPanel
            )
        )
        .colorScheme(.light)
    }
}
