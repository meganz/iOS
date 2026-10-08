import SwiftUI
import UIKit

/// Inline text with `inline code`, drawn by TextKit 1 with `InlineCodeLayoutManager`, like a rich editor row.
/// SwiftUI `Text` sizes a line of only code by the mono font. So it cannot keep the Figma chip lines,
/// which are as tall as the chip with a gap between them. `InlineTextView` uses this view only for text with code.
struct InlineCodeText: UIViewRepresentable {
    let text: AttributedString
    /// Nil: body text.
    let headingLevel: Int?
    let color: Color

    @Environment(\.markdownTheme) private var theme

    func makeUIView(context: Context) -> InlineCodeTextView {
        InlineCodeTextView()
    }

    func updateUIView(_ view: InlineCodeTextView, context: Context) {
        let environment = context.environment
        let traits = Self.traits(dynamicTypeSize: environment.dynamicTypeSize, legibilityWeight: environment.legibilityWeight)
        let resolved = theme.resolved(for: traits)
        let baseFont = headingLevel.map { resolved.headingFont(min(max($0, 1), 6)) } ?? resolved.bodyFont
        let direction: NSWritingDirection = environment.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
        view.configure(
            text: Self.attributedString(text, baseFont: baseFont, color: UIColor(color), resolved: resolved, direction: direction),
            baseFont: baseFont,
            resolved: resolved
        )
        view.openURL = { environment.openURL($0) }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: InlineCodeTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        return CGSize(width: width, height: uiView.height(forWidth: width))
    }

    /// The first baseline from the top, for the list marker. See `MarkdownTheme.Resolved.firstBaseline(of:hasInlineCode:startsWithInlineCode:)`.
    static func firstBaseline(headingLevel: Int?, startsWithCode: Bool, traits: UITraitCollection, theme: MarkdownTheme) -> CGFloat {
        let resolved = theme.resolved(for: traits)
        let baseFont = headingLevel.map { resolved.headingFont(min(max($0, 1), 6)) } ?? resolved.bodyFont
        return resolved.firstBaseline(of: baseFont, hasInlineCode: true, startsWithInlineCode: startsWithCode)
    }

    /// The traits that resolve the theme fonts, from the SwiftUI text size and weight.
    static func traits(dynamicTypeSize: DynamicTypeSize, legibilityWeight: LegibilityWeight?) -> UITraitCollection {
        UITraitCollection { traits in
            traits.preferredContentSizeCategory = UIContentSizeCategory(dynamicTypeSize)
            traits.legibilityWeight = legibilityWeight == .bold ? .bold : .regular
        }
    }

    /// The same attributes as a rich editor row: theme fonts, the code chip mark and raised code, link color.
    static func attributedString(
        _ text: AttributedString,
        baseFont: UIFont,
        color: UIColor,
        resolved: MarkdownTheme.Resolved,
        direction: NSWritingDirection
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        // A line of only inline code is lower than a plain line. This minimum keeps it as tall as a plain line.
        paragraph.minimumLineHeight = baseFont.ascender - baseFont.descender
        paragraph.alignment = .natural
        paragraph.baseWritingDirection = direction
        let result = NSMutableAttributedString()
        for run in text.runs {
            let intent = run.inlinePresentationIntent ?? []
            var font = baseFont
            var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color, .paragraphStyle: paragraph]
            if intent.contains(.code) {
                font = resolved.inlineCodeFont
                attributes[.foregroundColor] = resolved.inlineCodeColor
                attributes[.markdownInlineCode] = true
                attributes[.baselineOffset] = resolved.inlineCodeBaselineOffset
            }
            var traits: UIFontDescriptor.SymbolicTraits = []
            if intent.contains(.stronglyEmphasized) { traits.insert(.traitBold) }
            if intent.contains(.emphasized) { traits.insert(.traitItalic) }
            if !traits.isEmpty, let descriptor = font.fontDescriptor.withSymbolicTraits(font.fontDescriptor.symbolicTraits.union(traits)) {
                font = UIFont(descriptor: descriptor, size: font.pointSize)
            }
            attributes[.font] = font
            if intent.contains(.strikethrough) {
                attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }
            // The parser writes `<u>` as SwiftUI's underline attribute, not as an inline intent.
            if run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            if let link = run.link {
                attributes[.foregroundColor] = resolved.linkColor
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                attributes[.markdownLink] = link
            }
            result.append(NSAttributedString(string: String(text[run.range].characters), attributes: attributes))
        }
        return result
    }
}

extension NSAttributedString.Key {
    /// The URL of a link in `InlineCodeTextView`. Not `.link`: the view opens links itself, through SwiftUI `openURL`.
    static let markdownLink = NSAttributedString.Key("MEGAMarkdown.link")
}

/// Draws attributed text with `InlineCodeLayoutManager`. Read only: a tap on a link opens it.
/// At the start or end of a line the chip reaches past the text, so the text has `inset` of room on each side.
final class InlineCodeTextView: UIView {
    static let inset = InlineCodeLayoutManager.chipPadding

    var openURL: ((URL) -> Void)?

    private let storage = NSTextStorage()
    private let layoutManager = InlineCodeLayoutManager()
    private let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
    private var lastFit: (width: CGFloat, height: CGFloat)?

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        container.lineFragmentPadding = 0
        // SwiftUI `Text` adds no font leading between lines. The rich editor row does the same.
        layoutManager.usesFontLeading = false
        layoutManager.addTextContainer(container)
        layoutManager.delegate = self
        storage.addLayoutManager(layoutManager)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: InlineCodeTextView, _) in
            // Dynamic colors resolve while drawing.
            view.setNeedsDisplay()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: NSAttributedString, baseFont: UIFont, resolved: MarkdownTheme.Resolved) {
        layoutManager.fillColor = resolved.inlineCodeBackground
        layoutManager.borderColor = resolved.inlineCodeBorder
        let metricsChanged = layoutManager.baseFont != baseFont || layoutManager.chipHeight != resolved.inlineCodeChipHeight
            || layoutManager.lineGap != resolved.inlineCodeLineGap
        layoutManager.baseFont = baseFont
        layoutManager.chipHeight = resolved.inlineCodeChipHeight
        layoutManager.lineGap = resolved.inlineCodeLineGap
        if !storage.isEqual(to: text) {
            storage.setAttributedString(text)
        } else if metricsChanged {
            layoutManager.invalidateLayout(forCharacterRange: NSRange(location: 0, length: storage.length), actualCharacterRange: nil)
        } else {
            return
        }
        lastFit = nil
        accessibilityLabel = text.string
        accessibilityCustomActions = linkActions(in: text)
        setNeedsDisplay()
    }

    /// The view draws its text itself, so assistive tools cannot find the links in it.
    /// Each link becomes an action named by its text.
    private func linkActions(in text: NSAttributedString) -> [UIAccessibilityCustomAction] {
        var actions: [UIAccessibilityCustomAction] = []
        text.enumerateAttribute(.markdownLink, in: NSRange(location: 0, length: text.length)) { value, range, _ in
            guard let url = value as? URL else { return }
            let name = (text.string as NSString).substring(with: range)
            actions.append(UIAccessibilityCustomAction(name: name) { [weak self] _ in
                self?.openURL?(url)
                return true
            })
        }
        return actions
    }

    /// The height of the text at `width`. The last line has no gap below it.
    func height(forWidth width: CGFloat) -> CGFloat {
        if let lastFit, lastFit.width == width {
            return lastFit.height
        }
        container.size = CGSize(width: width - 2 * Self.inset, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: container)
        let height = ceil(layoutManager.textHeight(usedHeight: layoutManager.usedRect(for: container).height))
        lastFit = (width, height)
        return height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if container.size.width != bounds.width - 2 * Self.inset {
            container.size = CGSize(width: bounds.width - 2 * Self.inset, height: .greatestFiniteMagnitude)
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        let glyphs = layoutManager.glyphRange(for: container)
        let origin = CGPoint(x: Self.inset, y: 0)
        layoutManager.drawBackground(forGlyphRange: glyphs, at: origin)
        layoutManager.drawGlyphs(forGlyphRange: glyphs, at: origin)
    }

    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        var point = gesture.location(in: self)
        point.x -= Self.inset
        let glyph = layoutManager.glyphIndex(for: point, in: container)
        guard glyph < layoutManager.numberOfGlyphs,
              layoutManager.boundingRect(forGlyphRange: NSRange(location: glyph, length: 1), in: container).contains(point) else { return }
        let character = layoutManager.characterIndexForGlyph(at: glyph)
        if let url = storage.attribute(.markdownLink, at: character, effectiveRange: nil) as? URL {
            openURL?(url)
        }
    }
}

// MARK: - NSLayoutManagerDelegate

// The view lays out its text on the main thread.
extension InlineCodeTextView: @preconcurrency NSLayoutManagerDelegate {
    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<CGRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange
    ) -> Bool {
        self.layoutManager.setLineFragmentRect(lineFragmentRect, usedRect: lineFragmentUsedRect, baselineOffset: baselineOffset)
    }
}
