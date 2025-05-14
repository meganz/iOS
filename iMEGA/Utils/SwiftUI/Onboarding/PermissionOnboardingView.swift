import DeviceKit
import MEGADesignToken
import MEGAPresentation
import MEGAUIComponent
import SwiftUI

struct PermissionOnboardingView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let viewModel: PermissionOnboardingViewModel

    init(viewModel: PermissionOnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .task {
                await viewModel.onAppear()
            }
            .pageBackground()
            .ignoresSafeArea(.container, edges: .top)
            .navigationBarHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        if verticalSizeClass == .compact {
            landscapeView
        } else {
            portraitView
        }
    }

    private var portraitView: some View {
        VStack(spacing: .zero) {
            ScrollView {
                portraitContent
                    .padding(
                        .vertical,
                        Device.current.isPad ? TokenSpacing._17 : TokenSpacing._14
                    )
                    .padding(.horizontal, TokenSpacing._5)
            }
            VStack(spacing: TokenSpacing._5) {
                primaryButton
                secondaryButton
            }
            .padding(.horizontal, TokenSpacing._5)
        }
        .maxWidthForWideScreen()
    }

    private var landscapeView: some View {
        VStack {
            HStack {
                mainImageView
                    .frame(maxWidth: .infinity)
                ScrollView {
                    mainTextView
                    auxiliaryView
                }
            }
            .padding(.top)
            Divider()
            HStack(spacing: TokenSpacing._3) {
                secondaryButton
                primaryButton
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var portraitContent: some View {
        VStack(spacing: TokenSpacing._7) {
            mainImageView
            mainTextView
            auxiliaryView
        }
    }

    private var mainImageView: some View {
        Image(viewModel.image)
            .resizable()
            .frame(width: 200, height: 200)
    }

    private var mainTextView: some View {
        VStack(spacing: TokenSpacing._5) {
            Group {
                Text(viewModel.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                Text(viewModel.description)
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .tint(TokenColors.Link.primary.swiftUI)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var auxiliaryView: some View {
        if let note = viewModel.note {
            HStack(spacing: 0) {
                Image(.info)
                    .renderingMode(.template)
                    .foregroundColor(TokenColors.Support.info.swiftUI)
                    .frame(width: 20, height: 20)
                    .padding()
                AttributedTextView(
                    stringAttribute: .init(text: note.removeAllLocalizationTags(), font: .subheadline, foregroundColor: TokenColors.Text.primary.swiftUI),
                    substringAttributeList: [
                        .init(text: note.getLocalizationSubstring(tag: "B"),
                              font: .subheadline.weight(.bold)
                             )
                    ]
                )
                    .padding(.trailing, TokenSpacing._4)
            }
            .padding(.vertical, TokenSpacing._4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TokenColors.Notifications.notificationInfo.swiftUI)
            .clipShape(RoundedRectangle(cornerRadius: TokenRadius.medium))
        }
    }

    private var primaryButton: MEGAButton {
        MEGAButton(
            viewModel.primaryButtonTitle,
            type: .primary,
            action: {
                Task {
                    await viewModel.onPrimaryButtonTap()
                }
            }
        )
    }

    private var secondaryButton: MEGAButton {
        MEGAButton(
            viewModel.secondaryButtonTitle,
            type: .textOnly,
            action: {
                Task {
                    await viewModel.onSecondaryButtonTap()
                }
            }
        )
    }
}
