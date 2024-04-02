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
            var background: (ColorScheme) -> Color
            var foregroundUIColor: (ColorScheme) -> UIColor
            var foreground: (ColorScheme) -> Color
            var link: (ColorScheme) -> UIColor
            
            static var isDesignTokenEnabled: Bool {
                DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
            }
            
            // Meetings Floating panel only support dark mode
            static let darkMeetingsFloatingPanel: Self = .init(
                background: { _ in
                    isDesignTokenEnabled
                    ? TokenColors.Notifications.notificationWarning.swiftUI
                    : MEGAAppColor.Yellow._FED42926.color
                },
                foregroundUIColor: { _ in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary
                    : MEGAAppColor.Yellow._FFD60A.uiColor
                },
                foreground: { _ in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary.swiftUI
                    : MEGAAppColor.Yellow._FFD60A.color
                },
                link: { _ in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary
                    : MEGAAppColor.Yellow._FFD60A.uiColor
                }
            )
            
            static let dark: Self = .init(
                background: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Notifications.notificationWarning.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Yellow._FED42926.color : MEGAAppColor.Yellow._FED429.color
                },
                foregroundUIColor: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary
                    : colorScheme == .dark ? MEGAAppColor.Yellow._FFD60A.uiColor: MEGAAppColor.Yellow._9D8319.uiColor
                },
                foreground: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Yellow._FFD60A.color: MEGAAppColor.Yellow._9D8319.color
                },
                link: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary
                    : colorScheme == .dark ? MEGAAppColor.Yellow._FFD60A.uiColor: MEGAAppColor.Yellow._9D8319.uiColor
                }
            )
            
            static let light: Self = .init(
                background: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Background.page.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Black._000000.color : MEGAAppColor.White._F7F7F7.color
                },
                foregroundUIColor: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary
                    : colorScheme == .dark ? MEGAAppColor.White._FFFFFF.uiColor : MEGAAppColor.Black._000000.uiColor
                },
                foreground: { colorScheme in
                    isDesignTokenEnabled
                    ? TokenColors.Text.primary.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.White._FFFFFF.color : MEGAAppColor.Black._000000.color
                },
                link: { _ in 
                    isDesignTokenEnabled
                    ? TokenColors.Support.success
                    : MEGAAppColor.Green._00A886.uiColor
                }
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
        .background(config.theme.background(colorScheme))
        .onTapGesture {
            config.tapAction?()
        }
    }
    
    private var text: some View {
        TaggableText(
            config.copy,
            underline: config.underline,
            linkColor: { config.theme.link($0) }
        )
        .foregroundColor(config.theme.foreground(colorScheme))
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
                    .foregroundColor(config.theme.foreground(colorScheme))
                    .font(.system(size: 20))
            }
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
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
                    copy: Strings.Localizable.Meetings.WaitingRoom.Banner.Limit100Participants.nonOrganizerHost,
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
                    copy: Strings.Localizable.Meetings.WaitingRoom.Banner.Limit100Participants.nonOrganizerHost,
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
        .previewLayout(.sizeThatFits)
    }
}
