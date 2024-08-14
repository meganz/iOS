import MEGADesignToken
import SwiftUI

public struct BorderedTextEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var hasError: Bool = false
    @Binding var textInput: String
    @Binding var isFocused: Bool
    private let maxCharacterLimit: Int
    private let height: CGFloat
    
    public init(
        textInput: Binding<String>,
        isFocused: Binding<Bool>,
        maxCharacterLimit: Int = 0,
        height: CGFloat = 142
    ) {
        _textInput = textInput
        _isFocused = isFocused
        self.maxCharacterLimit = maxCharacterLimit
        self.height = height
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
                            guard shouldShowMaxLimit else { return }
                            hasError = text.count > maxCharacterLimit
                        }
                    
                    clearTextButton
                }
            }
            .frame(height: height)
            
            characterLimitCounterText
        }
    }
    
    @ViewBuilder
    private var characterLimitCounterText: some View {
        if shouldShowMaxLimit {
            Text("\(textInput.count)/\(maxCharacterLimit)")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(hasError ? TokenColors.Text.error.swiftUI : TokenColors.Text.secondary.swiftUI)
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

    private var shouldShowMaxLimit: Bool {
        maxCharacterLimit > 0
    }
    
    private var borderColor: Color {
        if hasError {
            return TokenColors.Support.error.swiftUI
        } else {
            return isFocused ? TokenColors.Border.strongSelected.swiftUI : TokenColors.Border.strong.swiftUI
        }
    }
}

#Preview {
    Group {
        BorderedTextEditorView(textInput: .constant("Show character counter"), isFocused: .constant(true), maxCharacterLimit: 120)
        BorderedTextEditorView(textInput: .constant("No character counter footer"), isFocused: .constant(false), maxCharacterLimit: 0)
    }
}
