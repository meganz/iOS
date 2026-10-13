import PDFKit

// Writes the benchmark fixtures, so the device only reads them.
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let basePages = Fixtures.makeBasePages(count: 1000)
for shape in OutlineShape.allCases {
    for count in [100, 1000, 5000, 20000] {
        let document = PDFDocument(data: basePages)!
        document.outlineRoot = Fixtures.buildOutline(shape: shape, totalItems: count, document: document)
        let url = output.appendingPathComponent("\(shape.rawValue)-\(count).pdf")
        precondition(document.write(to: url), "failed to write \(url.lastPathComponent)")
        print(url.lastPathComponent)
    }
}
