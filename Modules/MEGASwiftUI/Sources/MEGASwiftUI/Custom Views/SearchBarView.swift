import SwiftUI

public struct SearchBarView: View {
    @Binding var text: String
 
    @State private var isEditing = false
 
    var searchString: String
    var cancelString: String
    
    public init(text: Binding<String>, searchString: String, cancelString: String) {
        self._text = text
        self.searchString = searchString
        self.cancelString = cancelString
    }
    
    public var body: some View {
        HStack {
            TextField(searchString, text: $text)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                 
                        if isEditing && !text.isEmpty {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                )
                .onTapGesture {
                    self.isEditing = true
                }
 
            if isEditing {
                Button(action: {
                    self.isEditing = false
                    self.text = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text(cancelString)
                }
                .buttonStyle(BorderlessButtonStyle())
                .foregroundColor(.secondary)
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}
