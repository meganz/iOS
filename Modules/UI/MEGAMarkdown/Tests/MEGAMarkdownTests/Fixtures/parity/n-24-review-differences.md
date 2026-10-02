# Review 2 inputs where the new parser differs from the old one on purpose

Two images with nothing between them keep both URLs. The old parser kept only the first.

![a](1.png)![b](2.png)

A task marker inside bold, code, a link or a tag is plain text. The old parser made a checkbox and lost the style.

- **[x]** bold marker
- `[ ]` code marker
- [[x]](https://example.com) link marker
- <b>[x]</b> html marker

A tab after the marker is whitespace. The old parser needed a space.

- [x]	after tab

A style tag inside link text pairs only inside the link. The old parser kept every tag inside a link literal.

[<u>](https://example.com)</u>

[<u>a](https://example.com)</u>

[<u>a</u>](https://example.com)

A link with empty text keeps a placeholder. The old parser dropped the link.

[](https://example.com) tail

A task item that is only an image is an image block. The old parser kept a paragraph.

- [x] ![alt](u.png)
