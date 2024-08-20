import MEGADesignToken
import SwiftUI

public struct BorderedTextEditorView: View {
    public struct ViewConfig {
        /// Configures maximum character limit of the field.
        /// If 0, the footer counter will not be shown and it will not check for the maximum text input count.
        let maxCharacterLimit: Int
        
        /// Configures minimum character limit of the field.
        /// If 0, it will not check for the minimum text input count.
        let minCharacterLimit: Int
        
        /// Configures if the field is required or not.
        /// If true, it will check if the field is empty or not.
        let isRequired: Bool
        
        /// Provides the error warning icon if there's a field error.
        /// If nil, no icon will be shown.
        let errorWarningIcon: UIImage?
        
        /// Provides the error message if the field input is less than the `minCharacterLimit`.
        /// If nil, no error will be shown.
        let lessThanMinimumCharError: String?
        
        /// Provides the error message if the field is empty.
        /// If nil, no error will be shown.
        let emptyFieldError: String?
        
        /// Provides the height of the field.
        let height: CGFloat
        
        public init(
            maxCharacterLimit: Int = 0,
            minCharacterLimit: Int = 0,
            isRequired: Bool = false,
            errorWarningIcon: UIImage? = nil,
            lessThanMinimumCharError: String? = nil,
            emptyFieldError: String? = nil,
            height: CGFloat = 142
        ) {
            self.maxCharacterLimit = maxCharacterLimit
            self.minCharacterLimit = minCharacterLimit
            self.isRequired = isRequired
            self.errorWarningIcon = errorWarningIcon
            self.lessThanMinimumCharError = lessThanMinimumCharError
            self.emptyFieldError = emptyFieldError
            self.height = height
        }
    }
    
    enum ErrorState {
        case reachedMaxCharLimit, lessThanMinCharLimit, emptyField, none
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var errorState: ErrorState = .none
    @Binding var textInput: String
    @Binding var isFocused: Bool
    private let config: ViewConfig
    
    public init(
        textInput: Binding<String>,
        isFocused: Binding<Bool>,
        config: ViewConfig
    ) {
        _textInput = textInput
        _isFocused = isFocused
        self.config = config
    }
    
    public var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 2.0)
                    .background(
                        isDesignTokenEnabled ?
                        TokenColors.Background.page.swiftUI :
                            colorScheme == .dark ? Color(red: 19/255, green: 19/255, blue: 20/255) : .white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack(spacing: 0) {
                    TextEditorWithDoneKeyboardView(text: $textInput, isFocused: $isFocused)
                        .padding(2)
                        .background(.clear)
                        .onChange(of: textInput) { text in
                            if config.isRequired, text.isEmpty {
                                errorState = .emptyField
                            } else if shouldShowMaxLimit, text.count > config.maxCharacterLimit {
                                errorState = .reachedMaxCharLimit
                            } else if shouldCheckMinLimit, text.count < config.minCharacterLimit {
                                errorState = .lessThanMinCharLimit
                            } else {
                                errorState = .none
                            }
                        }
                        .onChange(of: isFocused) { isFocused in
                            if isFocused,
                               config.isRequired,
                               textInput.isEmpty {
                                errorState = .emptyField
                            }
                        }
                    
                    clearTextButton
                }
            }
            .frame(height: config.height)
            
            characterLimitCounterText
            
            minimumCharacterRequiredErrorView
        }
    }
    
    @ViewBuilder
    private var characterLimitCounterText: some View {
        if shouldShowMaxLimit {
            Text("\(textInput.count)/\(config.maxCharacterLimit)")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(errorState != .none ? TokenColors.Text.error.swiftUI : TokenColors.Text.secondary.swiftUI)
        }
    }
    
    @ViewBuilder
    private var clearTextButton: some View {
        if isFocused {
            Button {
                textInput = ""
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(isDesignTokenEnabled ? TokenColors.Icon.primary.swiftUI : .primary)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 10)
            .padding(.trailing, 10)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    @ViewBuilder
    private var minimumCharacterRequiredErrorView: some View {
        if errorState == .lessThanMinCharLimit || errorState == .emptyField {
            HStack(spacing: 10) {
                if let errorWarningIcon = config.errorWarningIcon {
                    Image(uiImage: errorWarningIcon.withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .frame(width: 16, height: 14)
                        .foregroundStyle(TokenColors.Support.error.swiftUI)
                }
                
                if let minimumErrorMessage {
                    Text(minimumErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(TokenColors.Text.error.swiftUI)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var minimumErrorMessage: String? {
        switch errorState {
        case .lessThanMinCharLimit: config.lessThanMinimumCharError
        case .emptyField: config.emptyFieldError
        default: nil
        }
    }
    
    private var shouldShowMaxLimit: Bool {
        config.maxCharacterLimit > 0
    }
    
    private var shouldCheckMinLimit: Bool {
        config.minCharacterLimit > 0
    }
    
    private var borderColor: Color {
        if errorState != .none {
            return TokenColors.Support.error.swiftUI
        } else {
            return isFocused ? TokenColors.Border.strongSelected.swiftUI : TokenColors.Border.strong.swiftUI
        }
    }
}

#Preview {
    Group {
        BorderedTextEditorView(textInput: .constant("Show character counter"), isFocused: .constant(true), config: BorderedTextEditorView.ViewConfig(maxCharacterLimit: 120))
        BorderedTextEditorView(textInput: .constant("No character counter footer"), isFocused: .constant(false), config: BorderedTextEditorView.ViewConfig(maxCharacterLimit: 0))
    }
}
