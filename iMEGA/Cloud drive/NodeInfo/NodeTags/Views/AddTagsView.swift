import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct AddTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var shouldDismiss = false

    private var navigationBarViewModel: AddTagsViewNavigationBarViewModel
    
    init(navigationBarViewModel: AddTagsViewNavigationBarViewModel) {
        self.navigationBarViewModel = navigationBarViewModel
    }
    
    public var body: some View {
        return content
            .background(TokenColors.Background.page.swiftUI)
            .onChange(of: shouldDismiss) {
                if $0 { dismiss() }
            }
    }
    
    var content: some View {
        VStack {
            topView
            bottomView
        }
    }
    
    var topView: some View {
        VStack {
            navigationBar
            textField
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, 10)
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
    
    var navigationBar: some View {
        AddTagsViewNavigationBar(viewModel: navigationBarViewModel, cancelButtonTapped: $shouldDismiss)
    }
    
    private var textField: some View {
        HStack(spacing: 0) {
            Text("#")
                .padding(.leading, TokenSpacing._3)
            TextField(
                "",
                text: .constant(""), // will be handled in [SAO-1818]
                prompt: textViewPlaceHolder
            )
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.vertical, 7)
            
        }
        .background(TokenColors.Background.surface2.swiftUI)
        .cornerRadius(TokenRadius.medium)
    }
    
    private var textViewPlaceHolder: Text {
        if #available(iOS 17.0, *) {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.inputPlaceHolder).foregroundStyle(TokenColors.Text.placeholder.swiftUI)
        } else {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.inputPlaceHolder).foregroundColor(TokenColors.Text.placeholder.swiftUI)
        }
    }
    
    private var bottomView: some View {
        VStack {
            hintView
            Color.clear // To be replaced in [SAO-1813]
        }
        .background(TokenColors.Background.page.swiftUI)
        
    }
    
    private var hintView: some View {
        Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.hint)
            .font(.system(.footnote))
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, TokenSpacing._3)
    }
}

#Preview {
     let navigationBarViewModel = AddTagsView.AddTagsViewNavigationBarViewModel(doneButtonDisabled: .constant(false))
     AddTagsView(navigationBarViewModel: navigationBarViewModel)
 }
