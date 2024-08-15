import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct HiddenFilesFoldersOnboardingView<PrimaryButtonView: View>: View {
    @Environment(\.dismiss) private var dismiss
    let primaryButton: PrimaryButtonView
    
    var body: some View {
        OnboardingNavigationBar {
            GeometryReader { geometry in
                ScrollView {
                    contentView()
                        .frame(width: geometry.size.width, alignment: .center)
                        .frame(minHeight: geometry.size.height,
                               alignment: .center)
                    
                }
            }
            .background(isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : nil)
        }
    }
    
    private func contentView() -> some View {
        VStack(spacing: 0) {
            Group {
                VStack(spacing: TokenSpacing._5) {
                    Image(.onboardingLock)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .padding(.top, TokenSpacing._5)
                    
                    Text(Strings.Localizable.Onboarding.HiddenFilesAndFolders.title)
                        .font(.headline)
                        .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                        .padding(.bottom, TokenSpacing._5)
                    
                    descriptionItemViews()
                }
                
                buttons()
                    .padding(.top, 43)
                    .padding(.bottom, 47)
            }
            .padding(.horizontal, TokenSpacing._9)
        }
    }
    
    private func descriptionItemViews() -> some View {
        VStack(alignment: .leading, spacing: TokenSpacing._5) {
            OnboardingItemView(image: .eyeOffRegular,
                               title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.HideImportant.Content.title,
                               description: Strings.Localizable.Onboarding.HiddenFilesAndFolders.HideImportant.Content.message)
            
            OnboardingItemView(image: .imagesRegular,
                               title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.ExcludeTimeline.Content.title,
                               description: Strings.Localizable.Onboarding.HiddenFilesAndFolders.ExcludeTimeline.Content.message)
            
            OnboardingItemView(image: .eyeRegular,
                               title: Strings.Localizable.Onboarding.HiddenFilesAndFolders.OutOfSight.Content.title,
                               description: Strings.Localizable.Onboarding.HiddenFilesAndFolders.OutOfSight.Content.message)
        }
    }
    
    private func buttons() -> some View {
        VStack(spacing: TokenSpacing._5) {
            primaryButton
                .frame(minWidth: 288)
            
            Button {
                dismiss()
            } label: {
                Text(Strings.Localizable.notNow)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.gray848484.swiftUI)
                    .font(.title3)
                    .frame(minWidth: 288, minHeight: 50)
                    .background(.clear)
                    .contentShape(Rectangle())
            }
        }
    }
}

private struct OnboardingNavigationBar<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        if isDesignTokenEnabled {
            NavigationStackView {
                content()
                    .toolbar {
                        dismissButton()
                    }
            }
        } else {
            clearNavigationBarView()
        }
    }
    
    @ViewBuilder
    private func clearNavigationBarView() -> some View {
        if #available(iOS 16.0, *) {
            NavigationStackView {
                content()
                    .toolbar {
                        dismissButton()
                    }
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
        } else {
            VStack(spacing: 0) {
                NavigationBarView(leading: { EmptyView() },
                                  trailing: { dismissButton() },
                                  center: { EmptyView() },
                                  backgroundColor: .clear)
                .frame(maxHeight: 44)
                
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func dismissButton() -> some View {
        Button {
            dismiss()
        } label: {
            Text(Strings.Localizable.cancel)
                .font(.body)
                .foregroundStyle(toolbarItemText)
        }
    }
    
    private var toolbarItemText: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.primary.swiftUI
        } else {
            colorScheme == .dark ? UIColor.grayD1D1D1.swiftUI : UIColor.gray515151.swiftUI
        }
    }
}

private struct OnboardingItemView: View {
    let image: ImageResource
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 0) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(
                    isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI :  UIColor.green00A886.swiftUI
                )
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(.leading, TokenSpacing._3)
                .padding(.trailing, TokenSpacing._5)
            
            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
                
                Text(description)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.caption)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : .primary)
            }
            .padding(.vertical, TokenSpacing._3)
            .padding(.trailing, TokenSpacing._3)
        }
    }
}

#Preview {
    HiddenFilesFoldersOnboardingView(primaryButton: Button("See Plans", action: {}))
}

#Preview {
    HiddenFilesFoldersOnboardingView(primaryButton: Button("Continue", action: {}))
        .preferredColorScheme(.dark)
}

#Preview {
    OnboardingItemView(image: .eyeOff,
                       title: "Hide important files and folders",
                       description: "You can now hide individual files and folders. Hidden files or folders can only be found browsing you Cloud drive.")
}

#Preview {
    OnboardingItemView(image: .eyeOff,
                       title: "Hide important files and folders",
                       description: "You can now hide individual files and folders. Hidden files or folders can only be found browsing you Cloud drive.")
    .preferredColorScheme(.dark)
}
