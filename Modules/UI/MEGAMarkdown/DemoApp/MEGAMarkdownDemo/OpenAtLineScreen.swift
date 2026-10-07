import SwiftUI

/// Opens an imported file at a line the user types, to try `restoreLine`.
struct OpenAtLineScreen: View {
    @State private var entries = ImportedFiles.entries()
    @State private var selected: TestFileEntry?
    @State private var lineText = "0"

    var body: some View {
        Form {
            Section("File") {
                Picker("Imported file", selection: $selected) {
                    ForEach(entries) { entry in
                        Text(entry.name).tag(Optional(entry))
                    }
                }
            }
            Section {
                TextField("Line", text: $lineText)
                    .keyboardType(.numberPad)
            } header: {
                Text("Line (0-based)")
            } footer: {
                Text("The field starts with the line the file showed last time, or 0. 0 means no scroll.")
            }
            if let selected {
                NavigationLink("Open", value: OpenAtLine(entry: selected, line: Int(lineText) ?? 0))
            }
        }
        .navigationTitle("Open at a line")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            entries = ImportedFiles.entries()
            selected = selected ?? entries.first
        }
        .onChange(of: selected) { _, entry in
            lineText = String(entry.flatMap { SavedLines.line(for: $0.url) } ?? 0)
        }
    }
}

struct OpenAtLine: Hashable {
    let entry: TestFileEntry
    let line: Int
}
