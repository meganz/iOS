import PDFKit
import AppKit

enum OutlineShape: String, CaseIterable {
    case flat
    case bookLike
    case deep
}

enum Fixtures {
    // Blank pages are enough: we are timing outline parsing, not page content.
    static func makeBasePages(count: Int) -> Data {
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        let data = NSMutableData()
        let context = CGContext(consumer: CGDataConsumer(data: data)!, mediaBox: &box, nil)!
        for _ in 0..<count {
            context.beginPDFPage(nil)
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    static func buildOutline(shape: OutlineShape, totalItems: Int, document: PDFDocument) -> PDFOutline {
        switch shape {
        case .flat:
            return buildFlat(totalItems: totalItems, document: document)
        case .bookLike:
            return buildBookLike(totalItems: totalItems, document: document)
        case .deep:
            return buildDeep(totalItems: totalItems, document: document)
        }
    }

    private static func destination(at index: Int, document: PDFDocument) -> PDFDestination? {
        let pageCount = document.pageCount
        guard pageCount > 0, let page = document.page(at: index % pageCount) else { return nil }
        return PDFDestination(page: page, at: .zero)
    }

    private static func buildFlat(totalItems: Int, document: PDFDocument) -> PDFOutline {
        let root = PDFOutline()
        for i in 0..<totalItems {
            let child = PDFOutline()
            child.label = "Item \(i)"
            child.destination = destination(at: i, document: document)
            root.insertChild(child, at: i)
        }
        return root
    }

    // Depth 3: chapters -> sections -> subsections. Chapter count is pinned at
    // 20 (or totalItems if smaller); sections/subsections per chapter are
    // solved from totalItems so the tree lands close to the requested count,
    // with any remainder padded as flat items at the root.
    private static func buildBookLike(totalItems: Int, document: PDFDocument) -> PDFOutline {
        let root = PDFOutline()
        guard totalItems > 0 else { return root }
        let chapterCount = min(20, totalItems)
        let perChapter = max(1, totalItems / chapterCount)
        let subsPerSection = 5
        let sectionsPerChapter = max(1, (perChapter - 1) / (1 + subsPerSection))
        var itemIndex = 0

        for c in 0..<chapterCount {
            if itemIndex >= totalItems { break }
            let chapter = PDFOutline()
            chapter.label = "Chapter \(c)"
            chapter.destination = destination(at: itemIndex, document: document)
            root.insertChild(chapter, at: c)
            itemIndex += 1

            var s = 0
            while s < sectionsPerChapter && itemIndex < totalItems {
                let section = PDFOutline()
                section.label = "Section \(c).\(s)"
                section.destination = destination(at: itemIndex, document: document)
                chapter.insertChild(section, at: s)
                itemIndex += 1

                var u = 0
                while u < subsPerSection && itemIndex < totalItems {
                    let sub = PDFOutline()
                    sub.label = "Subsection \(c).\(s).\(u)"
                    sub.destination = destination(at: itemIndex, document: document)
                    section.insertChild(sub, at: u)
                    itemIndex += 1
                    u += 1
                }
                s += 1
            }
        }

        var extraIndex = 0
        while itemIndex < totalItems {
            let extra = PDFOutline()
            extra.label = "Extra \(extraIndex)"
            extra.destination = destination(at: itemIndex, document: document)
            root.insertChild(extra, at: root.numberOfChildren)
            itemIndex += 1
            extraIndex += 1
        }
        return root
    }

    // Chains nested 10 levels deep, repeated as siblings under the root until
    // totalItems is reached.
    private static func buildDeep(totalItems: Int, document: PDFDocument) -> PDFOutline {
        let root = PDFOutline()
        let chainDepth = 10
        var itemIndex = 0
        var chainIndex = 0
        while itemIndex < totalItems {
            var parent = root
            var d = 0
            while d < chainDepth && itemIndex < totalItems {
                let node = PDFOutline()
                node.label = "Chain \(chainIndex) Level \(d)"
                node.destination = destination(at: itemIndex, document: document)
                parent.insertChild(node, at: parent.numberOfChildren)
                parent = node
                itemIndex += 1
                d += 1
            }
            chainIndex += 1
        }
        return root
    }
}
