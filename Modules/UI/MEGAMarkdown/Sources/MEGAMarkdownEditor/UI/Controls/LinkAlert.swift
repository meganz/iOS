import SwiftUI

/// The link dialog as a system alert, so it presents and dismisses like any native alert.
struct LinkAlert: ViewModifier {
    let model: RichEditorModel
    /// Runs after Save, Remove or Cancel, so the row gets the keyboard back.
    let onClose: () -> Void
    @Environment(\.markdownEditorStrings) private var strings
    @State private var url = ""
    @State private var text = ""

    func body(content: Content) -> some View {
        content
            .onChange(of: model.linkDialog) { _, dialog in
                guard let dialog else { return }
                url = dialog.draft.url
                text = dialog.draft.text
            }
            .alert(strings.linkDialogTitle, isPresented: isPresented) {
                TextField(strings.linkURLLabel, text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(strings.linkTextLabel, text: $text)
                Button(strings.linkSave) {
                    if model.saveLink(urlText: url, label: text) { onClose() }
                }
                .disabled(!model.canSaveLink(urlText: url))
                if model.linkDialog?.draft.isEditing == true {
                    Button(strings.linkRemove, role: .destructive) {
                        model.removeLink()
                        onClose()
                    }
                }
                Button(strings.linkCancel, role: .cancel) {
                    model.cancelLinkEditing()
                    onClose()
                }
            }
    }

    /// Only the model closes the dialog. A setter that cleared it could run before the Save action.
    private var isPresented: Binding<Bool> {
        Binding(get: { model.linkDialog != nil }, set: { _ in })
    }
}
