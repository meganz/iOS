import MEGADesignToken
import SwiftUI

public struct BorderedTextEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var hasError: Bool = false
    @FocusState private var isFocused: Bool
    @Binding var textInput: String
    @Binding var isFieldFocused: Bool
    private let maxCharacterLimit: Int
    private let height: CGFloat
    
    public init(
        textInput: Binding<String>,
        isFieldFocused: Binding<Bool>,
        maxCharacterLimit: Int = 0,
        height: CGFloat = 142
    ) {
        _textInput = textInput
        _isFieldFocused = isFieldFocused
        self.maxCharacterLimit = maxCharacterLimit
        self.height = height
        isFocused = isFieldFocused.wrappedValue
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
                    TextEditor(text: $textInput)
                        .transparentScrolling()
                        .focused($isFocused)
                        .padding(2)
                        .background(.clear)
                        .onChange(of: isFocused) { isFocused in
                            isFieldFocused = isFocused
                        }
                        .onChange(of: textInput) { text in
                            guard shouldShowMaxLimit else { return }
                            hasError = text.count > maxCharacterLimit
                        }
                    
                    clearTextButton
                }
            }
            
            characterLimitCounterText
        }
        .frame(height: height)
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

private extension View {
    func transparentScrolling() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
                .scrollIndicators(.never)
        } else {
            return onAppear {
                UITextView.appearance().backgroundColor = .clear
                UITextView.appearance().showsVerticalScrollIndicator = false
            }
        }
    }
}

#Preview {
    Group {
        BorderedTextEditorView(textInput: .constant("Show character counter"), isFieldFocused: .constant(true), maxCharacterLimit: 120)
        BorderedTextEditorView(textInput: .constant("No character counter footer"), isFieldFocused: .constant(false), maxCharacterLimit: 0)
    }
}
