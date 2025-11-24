import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct HiddenFilesFoldersOnboardingView<PrimaryButtonView: View>: View {
    @Environment(\.dismiss) private var dismiss
    let primaryButton: PrimaryButtonView
    let viewModel: HiddenFilesFoldersOnboardingViewModel
    
    var body: some View {
        navigationBar {
            GeometryReader { geometry in
                ScrollView {
                    contentView()
                        .frame(width: geometry.size.width, alignment: .center)
                        .frame(minHeight: geometry.size.height,
                               alignment: .center)
                    
                }
            }
            .background(TokenColors.Background.page.swiftUI)
        }
        .onAppear {
            viewModel.onViewAppear()
        }
    }
    
    @ViewBuilder
    private func navigationBar(@ViewBuilder content: @escaping () -> some View) -> some View {
        if viewModel.showNavigationBar {
            OnboardingNavigationBar(
                content: content,
                dismissAction: dismissAction)
        } else {
            content()
        }
    }
    
    private func contentView() -> some View {
        VStack(spacing: 0) {
            Group {
                VStack(spacing: TokenSpacing._5) {
                    MEGAAssets.Image.onboardingLock
                        .resizable()
                        .frame(width: 120, height: 120)
                        .padding(.top, TokenSpacing._5)
                    
                    Text(Strings.Localizable.Onboarding.HiddenFilesAndFolders.Header.title)
                        .font(.headline)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .padding(.bottom, TokenSpacing._5)
                    
                    descriptionItemViews()
                }
                
                buttons()
            }
            .padding(.horizontal, TokenSpacing._9)
        }
    }
    
    private func descriptionItemViews() -> some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            ForEach(viewModel.descriptionItems) {
                OnboardingItemView(viewModel: $0)
            }
        }
    }
    
    private func buttons() -> some View {
        Group {
            if viewModel.showPrimaryButtonOnly {
                primaryButton
                    .padding(.bottom, 35)
            } else {
                VStack(spacing: TokenSpacing._5) {
                    primaryButton
                    
                    Button(action: dismissAction) {
                        Text(Strings.Localizable.notNow)
                            .foregroundStyle(TokenColors.Text.primary.swiftUI)
                            .font(.title3)
                            .frame(minHeight: 50)
                            .background(.clear)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.bottom, 47)
            }
        }
        .frame(minWidth: 288)
        .padding(.top, 43)
    }
    
    private func dismissAction() {
        viewModel.onDismissButtonTapped()
        dismiss()
    }
}

private struct OnboardingNavigationBar<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    private let content: () -> Content
    let dismissAction: (() -> Void)
    
    public init(@ViewBuilder content: @escaping () -> Content, dismissAction: @escaping (() -> Void)) {
        self.content = content
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        NavigationStackView {
            content()
                .toolbar {
                    dismissButton()
                }
        }
    }
    
    @ViewBuilder
    private func clearNavigationBarView() -> some View {
        NavigationStackView {
            content()
                .toolbar {
                    dismissButton()
                }
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private func dismissButton() -> some View {
        Button {
            dismissAction()
        } label: {
            Text(Strings.Localizable.cancel)
                .font(.body)
                .foregroundStyle(toolbarItemText)
        }
    }
    
    private var toolbarItemText: Color {
        TokenColors.Text.primary.swiftUI
    }
}

private struct OnboardingItemView: View {
    let viewModel: HiddenFilesFoldersOnboardingViewModel.DescriptionItemViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            viewModel.icon
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(TokenColors.Icon.accent.swiftUI)
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(.leading, TokenSpacing._3)
                .padding(.trailing, TokenSpacing._5)
            
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(viewModel.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                descriptionText
            }
            .padding(.vertical, TokenSpacing._3)
            .padding(.trailing, TokenSpacing._3)
        }
    }
    
    private var descriptionText: some View {
        AttributedTextView(
            stringAttribute: .init(
                text: viewModel.description,
                font: .caption,
                foregroundColor: TokenColors.Text.primary.swiftUI),
            substringAttributeList: viewModel.descriptionHighlightedText.map { highlight in
                [
                    .init(
                        text: highlight.text,
                        attributes: AttributeContainer()
                            .font(.caption.weight(.semibold))
                            .foregroundColor(TokenColors.Link.primary.swiftUI),
                        action: highlight.action
                    )
                ]
            } ?? []
        )
    }
}
