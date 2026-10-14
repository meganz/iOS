#!/usr/bin/env python3
"""Writes the Markdown test files for the demo app and for manual tests in other apps.

Usage: make_test_files.py <output folder> [--skip-large]

Each file name says what the case is. Folders group the cases by topic.
The large files take about 260 MB. --skip-large leaves them out.
The output is deterministic: the same script gives the same bytes.
"""

import os
import random
import re
import shutil
import sys
import textwrap

PACKAGE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FIXTURES = os.path.join(PACKAGE, "Tests", "MEGAMarkdownTests", "Fixtures")
IMAGES = os.path.join(PACKAGE, "Tests", "MEGAMarkdownSnapshotTests", "Images")

out = ""
counts = {}


def write(path, text, dedent=True, newline="\n"):
    """Writes UTF-8 text. `newline` replaces every "\\n", so a file can use CRLF or lone CR."""
    if dedent:
        text = textwrap.dedent(text).lstrip("\n")
    data = text.replace("\n", newline).encode("utf-8")
    write_bytes(path, data)


def write_bytes(path, data):
    full = os.path.join(out, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "wb") as f:
        f.write(data)
    top = path.split("/")[0]
    counts[top] = counts.get(top, 0) + 1


def fixture(name):
    with open(os.path.join(FIXTURES, name), "rb") as f:
        return f.read()


# MARK: - Topics


def overview():
    write_bytes("overview/all-block-kinds-short.md", fixture("all-blocks.md"))
    write("overview/every-feature-tour.md", """
        # Every feature tour

        A short file with one example of each feature. Open the topic folders for the edge cases.

        ## Inline styles

        **Bold**, *italic*, ***bold italic***, ~~strikethrough~~, `inline code`, <u>underline</u>,
        a [link](https://mega.io), an autolink https://mega.io and an email help@mega.io.

        ## Lists

        - Bullet
          - Nested bullet
        1. Ordered
        2. Second

        - [ ] Open task
        - [x] Done task

        ## Quote

        > A quote with **bold** text.
        >
        > > A nested quote.

        ## Code

        ```swift
        let greeting = "Hello, MEGA"
        print(greeting)
        ```

        ## Table

        | Name | Size | Type |
        |:-----|-----:|:----:|
        | notes.md | 12 KB | Text |
        | photo.jpg | 3.4 MB | Image |

        ## Image

        ![Wide test image](../images/local/assets/wide.png)

        ---

        The end.
        """)


def headings():
    write("headings/atx-levels-1-to-6.md", """
        # Heading level 1
        ## Heading level 2
        ### Heading level 3
        #### Heading level 4
        ##### Heading level 5
        ###### Heading level 6

        Paragraph after the headings.
        """)
    write("headings/atx-seven-hashes-is-paragraph.md", """
        ####### Seven hashes is a paragraph

        #NoSpaceIsAParagraph

        \\# Escaped hash is a paragraph
        """)
    write("headings/atx-closing-hashes-removed.md", """
        # Closing hashes are removed ##
        ## Many closing hashes ##################
        ### Hash inside text # stays ###
        #### Escaped closing hash \\###
        ##### foo#
        """)
    write("headings/atx-inline-styles.md", """
        # Heading with **bold**, *italic* and `code`
        ## Heading with a [link](https://mega.io)
        ### Heading with ~~strike~~ and <u>underline</u>
        #### Heading with emoji 🚀 and an image ![icon](../images/local/assets/wide.png)
        """)
    write("headings/atx-empty-headings.md", """
        #

        ##

        ### ###

        Text between empty headings.

        ######
        """)
    # Written without dedent, so each line keeps its exact leading spaces.
    write("headings/atx-indented-up-to-three-spaces.md",
          " # One space\n  ## Two spaces\n   ### Three spaces\n    #### Four spaces is code\n", dedent=False)
    write("headings/setext-equals-and-dashes.md", """
        Setext heading level 1
        ======================

        Setext heading level 2
        ----------------------

        Short underline
        =
        """)
    write("headings/setext-multi-line-title.md", """
        A setext heading
        on two lines
        ============

        A paragraph, then a dash line that makes it a heading
        ---
        """)
    write("headings/setext-vs-list-and-thematic-break.md", """
        - item
        ---

        Para line
        ***

        ---
        """)
    write("headings/heading-very-long-wraps.md", "# " + " ".join(["A very long heading that wraps"] * 12) + "\n\n" +
          "## " + "x" * 400 + "\n", dedent=False)
    write("headings/headings-back-to-back-with-paragraphs.md", "".join(
        f"{'#' * (i % 6 + 1)} Heading {i + 1}\n\nParagraph under heading {i + 1}.\n\n" for i in range(60)), dedent=False)


def paragraphs_and_breaks():
    write("paragraphs-and-breaks/soft-break-shown-as-line-break.md", """
        Line one of the paragraph.
        Line two after a single newline (a soft break).
        Line three. The preview shows each line on its own row, like Android.
        """)
    write("paragraphs-and-breaks/hard-break-two-spaces.md",
          "Two trailing spaces make a hard break.  \nThe next line.  \nAnd one more.\n", dedent=False)
    write("paragraphs-and-breaks/hard-break-backslash.md", """
        A backslash at the end makes a hard break.\\
        The next line.\\
        And one more.
        """)
    # Written without dedent, so the two trailing spaces stay in the file.
    write("paragraphs-and-breaks/backslash-at-paragraph-end-is-literal.md",
          "The backslash at the end of a paragraph stays visible.\\\n\n"
          "Two spaces at the end of a paragraph are dropped.  \n", dedent=False)
    write("paragraphs-and-breaks/hard-break-inside-styles.md",
          "**bold  \nbold after break** and *italic\\\nitalic after break*\n\n**bold\nsoft**\n", dedent=False)
    write("paragraphs-and-breaks/blank-lines-between-paragraphs.md",
          "First paragraph.\n\n\n\n\nSecond paragraph after four blank lines.\n\n   \n\t\nThird paragraph after whitespace lines.\n",
          dedent=False)
    write("paragraphs-and-breaks/leading-spaces-up-to-three.md",
          " One space.\n  Two spaces.\n   Three spaces.\n\n    Four spaces is code.\n", dedent=False)
    write("paragraphs-and-breaks/many-short-paragraphs.md",
          "".join(f"Paragraph {i + 1} is short.\n\n" for i in range(300)), dedent=False)
    write("paragraphs-and-breaks/thematic-breaks-all-styles.md", """
        Dashes:

        ---

        Stars:

        ***

        Underscores:

        ___

        Spaced:

        - - -

        * * * * *

        Long:

        ------------------------------------------

        Two dashes are not a break:

        --
        """)


def emphasis():
    p = "emphasis/"
    write(p + "bold-italic-basic.md", """
        **bold with stars** and __bold with underscores__

        *italic with star* and _italic with underscore_

        ***bold italic*** and ___bold italic___ and **_mixed_** and *__mixed__*
        """)
    write(p + "nested-emphasis.md", """
        *italic **bold inside italic** italic*

        **bold *italic inside bold* bold**

        ***all*** then **bold *both* bold** then *a **b** c*

        **bold ~~strike `code` strike~~ bold**
        """)
    write(p + "strikethrough-one-two-three-tildes.md", """
        ~~two tildes~~ and ~one tilde~ and ~~~three tildes~~~ (not strike)

        ~~strike with **bold** inside~~

        a~~b~~c inside a word
        """)
    write(p + "intraword-underscore-and-star.md", """
        snake_case_word stays plain.

        foo*bar*baz has italic in the middle.

        foo_bar_baz stays plain.

        **a**b and _a_b and a*b*
        """)
    write(p + "emphasis-rules-left-and-right-flanking.md", """
        a * not italic because of the space *

        *italic*.

        **not bold **

        *(*foo*)*

        _foo_bar_baz_

        ***strong emph***

        **foo "*bar*" foo**
        """)
    write(p + "code-spans.md", """
        Use `a*b*` and `` `x` `` and ` y ` and `` ` ``.

        A code span `with **no** _styles_ [inside](x)`.

        Unclosed `backtick stays literal.

        A very long code span `""" + "long_code_span_" * 30 + """end` in a paragraph.
        """)
    write(p + "backslash-escapes.md", """
        \\*not italic\\* \\_not italic\\_ \\`not code\\` \\[not a link\\](x) \\# not heading \\\\ backslash \\a stays

        \\- not a list

        1\\. not ordered

        \\> not a quote
        """)
    write(p + "entities-named-and-numeric.md", """
        &amp; &lt;tag&gt; &copy; &#169; &#x1F600; &nbsp;x &quot;quoted&quot; &bogus; &nosuch;

        Entity in code stays literal: `&amp;`

        [Entity in URL](https://example.com/?a=1&amp;b=2)
        """)
    write(p + "smart-punctuation-stays-literal.md", """
        "double quotes" 'single quotes' -- double dash --- triple dash ... dots
        """)
    write(p + "mixed-styles-long-paragraph.md", " ".join(
        ["Words with **bold**, *italic*, `code`, ~~strike~~ and a [link](https://mega.io)."] * 80) + "\n", dedent=False)
    write(p + "underline-html-tag.md", """
        <u>underlined text</u> and <u>**bold underline**</u> and **<u>underline in bold</u>**

        <u>open underline without close

        <U>upper case tag</U>
        """)


def links():
    p = "links/"
    write(p + "inline-links-with-titles.md", """
        [plain link](https://mega.io)

        [link with title](https://mega.io "MEGA title")

        [link with **bold** and `code`](https://mega.io/docs)

        [link in angle brackets](<https://mega.io/a b>)
        """)
    write(p + "reference-links-full-collapsed-shortcut.md", """
        Full [one][r1], collapsed [r2][], shortcut [r3], and [missing][nope].

        [r1]: https://example.com/1
        [r2]: https://example.com/2 "Title two"
        [r3]: <https://example.com/3>
        """)
    write_bytes(p + "reference-definitions-at-end.md", fixture("parity/e-02-link-defs-at-end.md"))
    write_bytes(p + "reference-definitions-everywhere.md", fixture("parity/n-02-defs-everywhere.md"))
    write_bytes(p + "reference-label-on-two-lines.md", fixture("parity/e-04-label-two-lines.md"))
    write(p + "reference-label-case-folding.md", """
        [STRASSE] and [Straße] and [straße] and [FOO] all resolve.

        [straße]: https://example.com/strasse
        [foo]: https://example.com/foo
        """)
    write(p + "autolinks-angle-brackets.md", """
        <https://mega.io> and <http://example.com/path?q=1> and <ftp://files.example.com>

        <help@mega.io> and <mailto:help@mega.io>

        <not a link> and <https://with space.com>
        """)
    write(p + "autolinks-gfm-bare-www-and-https.md", """
        www.mega.io and https://mega.io/x?y=1. and http://example.com/a_(b)

        Trailing punctuation: https://mega.io, https://mega.io! https://mega.io? (https://mega.io)

        a@b.com and first.last+tag@example.co.nz
        """)
    write_bytes(p + "autolinks-mixed.md", fixture("parity/n-15-autolinks.md"))
    write(p + "relative-links-use-base-url.md", """
        These links resolve against the folder of this file.

        - [Sibling file](reference-links-full-collapsed-shortcut.md)
        - [File in another folder](../headings/atx-levels-1-to-6.md)
        - [Absolute path](/root/file.md)
        - [Fragment only](#top)
        - [Link with spaces](<my file.md>)
        """)
    write_bytes(p + "link-edge-cases.md", fixture("parity/v-22-link-edge.md"))
    write(p + "long-url-wraps.md", "A long URL https://example.com/" + "very/long/path/segment/" * 20 +
          "end.html in the text.\n\n[A long link text " + "that goes on " * 30 + "](https://mega.io)\n", dedent=False)
    write(p + "many-links-in-one-paragraph.md",
          " ".join(f"[link {i}](https://example.com/{i})" for i in range(200)) + "\n", dedent=False)


def images():
    p = "images/"
    for name in ("wide.png", "tall.png"):
        with open(os.path.join(IMAGES, name), "rb") as f:
            write_bytes(p + "local/assets/" + name, f.read())
    write(p + "local/relative-paths.md", """
        Four images, each in its own paragraph. All four show when local images load.

        ![Wide image](assets/wide.png)

        ![Tall image](assets/tall.png)

        ![Same folder path](./assets/wide.png)

        ![Parent folder path](../local/assets/wide.png)
        """)
    write(p + "local/missing-file-shows-alt-text.md", """
        ![This file does not exist](assets/missing.png)

        ![](assets/missing-with-empty-alt.png)
        """)
    write(p + "local/inline-image-in-text.md", """
        Alt text expected: an image mixed with text shows its alt text only, like Android.

        Text with an inline image ![wide](assets/wide.png) in the middle of a sentence.

        Two images side by side: ![a](assets/wide.png)![b](assets/tall.png)
        """)
    write(p + "remote/remote-images.md", """
        The PNG and the JPEG show when remote images load. The SVG and the broken URL show their alt text.

        ![A PNG from GitHub](https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png)

        ![A JPEG from picsum](https://picsum.photos/id/10/600/300.jpg)

        ![An SVG badge](https://img.shields.io/badge/markdown-preview-red.svg)

        ![A broken URL](https://example.invalid/missing.png)
        """)
    write(p + "remote/image-with-title.md", """
        ![Alt text](https://picsum.photos/id/20/400/200.jpg "The image title")
        """)
    write_bytes(p + "alt-text-with-styles.md", fixture("parity/n-13-images.md"))
    write_bytes(p + "empty-alt-text.md", fixture("parity/n-22-empty-alt-images.md"))
    write_bytes(p + "images-inside-links-badges.md", fixture("parity/n-23-images-in-links.md"))
    write(p + "image-with-empty-url-is-text.md", """
        ![alt with empty url]()

        ![alt]( )
        """)
    write(p + "local/reference-style-images.md", """
        A full reference and a collapsed reference. Both images show.

        ![Reference image][logo]

        ![collapsed][]

        [logo]: assets/wide.png
        [collapsed]: assets/tall.png
        """)
    write(p + "local/two-images-only-paragraph.md", """
        Alt text expected: two images with nothing between them stay inline in one paragraph,
        so both show their alt text. GitHub shows both images.

        ![first](assets/wide.png)![second](assets/tall.png)
        """)
    write(p + "remote/reference-style-image.md", """
        A shortcut reference to a remote image.

        ![shortcut]

        [shortcut]: https://picsum.photos/id/30/300/150.jpg
        """)
    write(p + "remote/large-and-tall-images.md", """
        A large image scales down to the screen width.

        ![Large 2400 x 1600](https://picsum.photos/id/40/2400/1600.jpg)

        A tall image is limited in height.

        ![Tall 600 x 2400](https://picsum.photos/id/50/600/2400.jpg)
        """)


def lists():
    p = "lists/"
    write(p + "bullets-dash-star-plus.md", """
        - dash one
        - dash two

        * star one
        * star two

        + plus one
        + plus two
        """)
    write(p + "nested-bullets-10-levels.md", "".join("  " * i + f"- level {i}\n" for i in range(10)), dedent=False)
    write(p + "ordered-start-number-7.md", """
        7. seven
        8. eight
        9. nine
        10. ten (two digits)
        """)
    write(p + "ordered-start-number-0-and-large.md", """
        0. zero

        123456789. nine digits

        1234567890. ten digits is a paragraph
        """)
    write(p + "ordered-paren-delimiter.md", """
        1) one
        2) two
        3) three

        1. dot list
        1) paren starts a new list
        """)
    write(p + "ordered-same-number-every-item.md", """
        1. one
        1. two
        1. three
        """)
    write(p + "tight-vs-loose.md", """
        Both lists look the same: the preview does not keep the tight or loose difference.

        Tight:

        - a
        - b
        - c

        Loose:

        - a

        - b

        - c
        """)
    write_bytes(p + "empty-items.md", fixture("parity/n-11-empty-items.md"))
    write(p + "item-with-code-quote-and-table.md", """
        - An item with a code block:

          ```swift
          let x = 1
          ```

        - An item with a quote:

          > quoted

        - An item with a table:

          | A | B |
          |---|---|
          | 1 | 2 |

        - An item with an indented code block:

              indented code
        """)
    write(p + "item-with-multiple-paragraphs.md", """
        1. First paragraph of item one.

           Second paragraph of item one.

        2. Item two.

           - nested bullet

           Paragraph after the nested list.
        """)
    write(p + "nested-ordered-and-unordered.md", """
        1. ordered
           - bullet
             1. ordered again
                - bullet again
        2. back to top
           > quote in item
           > - list in quote in item
        """)
    write(p + "list-interrupts-paragraph.md", """
        A paragraph
        - starts a list without a blank line

        A paragraph
        2. ordered not starting at 1 does not interrupt

        A paragraph
        1. ordered starting at 1 does interrupt
        """)
    write(p + "long-item-text-wraps.md", "- " + "A long list item that wraps over many lines. " * 20 +
          "\n  - " + "A long nested item. " * 30 + "\n", dedent=False)
    write(p + "list-1000-items.md", "".join(f"- item {i + 1}\n" for i in range(1000)), dedent=False)
    write(p + "ordered-list-1000-items.md", "".join(f"{i + 1}. item {i + 1}\n" for i in range(1000)), dedent=False)


def task_lists():
    p = "task-lists/"
    write(p + "open-and-done.md", """
        - [ ] open task
        - [x] done task
        - normal item
        """)
    write(p + "uppercase-x-is-done.md", """
        - [X] upper case X
        - [x] lower case x
        """)
    write_bytes(p + "empty-and-not-task-markers.md", fixture("parity/n-08-tasks.md"))
    write(p + "nested-tasks.md", """
        - [ ] parent task
          - [x] child done
          - [ ] child open
            - [x] grandchild done
        - [x] second parent
        """)
    write(p + "ordered-task-list.md", """
        1. [ ] first
        2. [x] second
        3. [ ] third
        """)
    write(p + "task-marker-inside-styles-is-text.md", """
        - **[x]** bold marker
        - `[ ]` code marker
        - [[x]](https://example.com) link marker
        - <b>[x]</b> tag marker
        """)
    write(p + "task-with-long-wrapping-text.md",
          "- [ ] " + "A long task that wraps over many lines. " * 15 + "\n- [x] " + "A long done task. " * 25 + "\n",
          dedent=False)
    write(p + "task-with-styles-in-text.md", """
        - [ ] **bold** task with `code` and a [link](https://mega.io)
        - [x] ~~struck~~ done task
        """)
    write(p + "task-list-500-items.md",
          "".join(f"- [{'x' if i % 3 == 0 else ' '}] task {i + 1}\n" for i in range(500)), dedent=False)


def quotes():
    p = "quotes/"
    write(p + "basic-quote.md", """
        > A quote with **bold**, *italic* and `code`.
        > The second line after a soft break.
        """)
    write(p + "nested-quotes-10-levels.md", "> " * 10 + "ten levels deep\n\n" +
          "".join("> " * (i + 1) + f"level {i + 1}\n" + "> " * (i + 1) + "\n" for i in range(5)), dedent=False)
    write(p + "lazy-continuation.md", """
        > a quote line
        lazy line without the marker
        > - item
        lazy item line
        """)
    write(p + "quote-with-heading-list-code-table.md", """
        > # Heading in a quote
        >
        > - list in a quote
        > - [x] task in a quote
        >
        > ```
        > code in a quote
        > ```
        >
        > | A | B |
        > |---|---|
        > | 1 | 2 |
        >
        > ---
        """)
    write_bytes(p + "nested-mix-quote-list-code.md", fixture("parity/n-18-nested-mix.md"))
    write(p + "quote-empty-and-blank.md", """
        >

        >
        >
        > text after blank quote lines
        """)
    write(p + "long-quote-wraps.md", "> " + "A long quoted paragraph. " * 60 + "\n", dedent=False)
    write(p + "many-quotes-in-a-row.md", "".join(f"> Quote {i + 1}\n\n" for i in range(200)), dedent=False)


def code():
    p = "code/"
    write(p + "fenced-with-language.md", """
        ```swift
        struct Item {
            let name: String
        }
        ```

        ```kotlin
        data class Item(val name: String)
        ```

        ```json
        { "name": "item" }
        ```
        """)
    write(p + "fenced-with-tildes.md", """
        ~~~
        tilde fence
        ~~~

        ~~~~python
        print("four tildes")
        ~~~~
        """)
    write(p + "indented-code.md", """
        Paragraph.

            indented code line one
            indented code line two

                more indented line
        """)
    write_bytes(p + "info-string-with-attributes.md", fixture("parity/n-12-code-info.md"))
    write(p + "empty-code-blocks.md", """
        ```
        ```

        ```

        ```

        ```swift
        ```
        """)
    write(p + "long-lines-scroll-sideways.md", "```text\n" +
          "\n".join(f"line {i}: " + "a long code line that does not wrap " * 12 for i in range(30)) + "\n```\n",
          dedent=False)
    write(p + "unclosed-fence-runs-to-end.md", """
        Paragraph before.

        ```
        code without a closing fence

        # not a heading

        - not a list
        """)
    write_bytes(p + "fence-inside-html-block.md", fixture("parity/e-01-fence-in-html.md"))
    write_bytes(p + "fence-inside-div.md", fixture("parity/n-01-fence-in-div.md"))
    write(p + "markdown-characters-inside-code.md", """
        ```
        # not a heading
        **not bold** *not italic* `not code`
        - not a list
        > not a quote
        | not | a table |
        <u>not html</u>
        ```
        """)
    write(p + "tabs-inside-code.md", "```\n\tone tab\n\t\ttwo tabs\nmixed\t tab and space\n```\n\n\tindented code with a tab\n",
          dedent=False)
    write(p + "unicode-and-emoji-inside-code.md", """
        ```
        let 名前 = "日本語"   // CJK
        let emoji = "👨‍👩‍👧‍👦 🇳🇿 ✅"
        let rtl = "مرحبا שלום"
        ```
        """)
    write(p + "code-block-5000-lines.md",
          "```swift\n" + "".join(f"let value{i} = {i} // line {i + 1}\n" for i in range(5000)) + "```\n", dedent=False)
    write(p + "many-small-code-blocks.md", "".join(f"```\nblock {i + 1}\n```\n\n" for i in range(200)), dedent=False)


def tables():
    p = "tables/"
    write(p + "basic-alignment.md", """
        | Left | Center | Right | None |
        |:-----|:------:|------:|------|
        | a | b | c | d |
        | longer left | longer center | longer right | longer none |
        """)
    wide_header = "|" + "".join(f" Column {i} |" for i in range(1, 41))
    wide_delim = "|" + "---|" * 40
    wide_row = "|" + "".join(f" value {i} |" for i in range(1, 41))
    write(p + "table-wide-columns-scroll.md", f"{wide_header}\n{wide_delim}\n{wide_row}\n{wide_row}\n", dedent=False)
    write(p + "table-inline-styles.md", """
        | Style | Example |
        |---|---|
        | bold | **bold** |
        | italic | *italic* |
        | code | `code` |
        | strike | ~~strike~~ |
        | link | [MEGA](https://mega.io) |
        | underline | <u>under</u> |
        | autolink | https://mega.io |
        """)
    write(p + "table-escaped-pipe.md", """
        | Input | Output |
        |---|---|
        | `a\\|b` | pipe in code |
        | a \\| b | escaped pipe |
        """)
    write_bytes(p + "table-ragged-rows.md", fixture("parity/n-09-tables.md"))
    write(p + "table-empty-cells.md", """
        | A | B | C |
        |---|---|---|
        |   | 2 |   |
        | 1 |   | 3 |
        |   |   |   |
        """)
    write(p + "table-header-only.md", """
        | Only | A | Header |
        |---|---|---|
        """)
    write(p + "table-long-cell-text.md", "| Short | Long |\n|---|---|\n| a | " + "A long cell text that wraps. " * 20 +
          "|\n| b | " + "x" * 300 + " |\n", dedent=False)
    write(p + "table-1000-rows.md", "| Row | Value | Note |\n|---|:-:|--:|\n" +
          "".join(f"| {i} | v{i} | `n{i}` |\n" for i in range(1000)), dedent=False)
    write(p + "table-in-list-and-quote.md", """
        - item

          | A | B |
          |---|---|
          | 1 | 2 |

        > | C | D |
        > |---|---|
        > | 3 | 4 |
        """)
    write(p + "table-images-in-cells.md", """
        | Image | Name |
        |---|---|
        | ![wide](../images/local/assets/wide.png) | wide |
        | ![](../images/local/assets/tall.png) | empty alt |
        """)
    write(p + "table-without-leading-pipes.md", """
        A | B
        --|--
        1 | 2
        """)
    write(p + "not-a-table.md", """
        | A | B |
        | 1 | 2 |

        | A | B |
        |---|
        | 1 | 2 |
        """)
    write(p + "table-interrupts-paragraph.md", """
        A paragraph line
        | A | B |
        |---|---|
        | 1 | 2 |
        """)


def html():
    p = "html/"
    write_bytes(p + "html-block-div-and-comment.md", fixture("parity/n-16-html-blocks.md"))
    write(p + "html-comment-block-shows-as-text.md", """
        Before the comment.

        <!-- This comment
        is hidden
        # and this is not a heading
        -->

        After the comment.
        """)
    write_bytes(p + "inline-html-tags.md", fixture("parity/v-09-inline-html-u.md"))
    write_bytes(p + "inline-html-nested-styles.md", fixture("parity/v-10-inline-html-nested.md"))
    write_bytes(p + "style-tags-strong-em-del-code.md", fixture("parity/n-07-style-tags.md"))
    write_bytes(p + "style-tags-beside-other-html.md", fixture("parity/n-24-style-tags-beside-html.md"))
    write_bytes(p + "html-comment-inline.md", fixture("parity/v-28-html-comment-inline.md"))
    write(p + "details-and-summary.md", """
        <details>
        <summary>Click to expand</summary>

        Hidden **content** inside details.

        </details>
        """)
    write(p + "script-style-and-iframe.md", """
        <script>alert("script");</script>

        <style>p { color: red; }</style>

        <iframe src="https://mega.io"></iframe>

        Text after.
        """)
    write(p + "img-and-br-tags.md", """
        An img tag: <img src="../images/local/assets/wide.png" alt="wide" width="100">

        Line one<br>line two<br/>line three
        """)
    write(p + "html-table.md", """
        <table>
          <tr><th>A</th><th>B</th></tr>
          <tr><td>1</td><td>2</td></tr>
        </table>
        """)


def footnotes_and_definitions():
    p = "footnotes-and-definitions/"
    write_bytes(p + "footnote-basic.md", fixture("parity/v-25-footnote.md"))
    write(p + "footnotes-multiple-and-named.md", """
        First note[^1], named note[^note], and a missing note[^missing].

        [^1]: The first note.
        [^note]: A named note with **bold** text.
            It has a second indented line.
        """)
    write(p + "link-definitions-only-shows-nothing.md", """
        [a]: https://example.com/a
        [b]: https://example.com/b "Title"
        """)
    write(p + "definition-inside-quote-and-list.md", """
        Use [q] and [l].

        > [q]: https://example.com/q

        - [l]: https://example.com/l
        """)
    write_bytes(p + "extended-attributes-stay-literal.md", fixture("parity/v-31-extended-attr.md"))


def right_to_left():
    p = "right-to-left/"
    write(p + "arabic-paragraphs.md", """
        # عنوان باللغة العربية

        هذه فقرة باللغة العربية مع **نص عريض** و*نص مائل* و`رمز` ورابط [ميغا](https://mega.io).
        هذا سطر ثان بعد فاصل سطر.

        فقرة ثانية أطول قليلا لاختبار التفاف النص عندما يكون السطر طويلا جدا ولا يتسع لعرض الشاشة.
        """)
    write(p + "hebrew-paragraphs.md", """
        # כותרת בעברית

        זוהי פסקה בעברית עם **טקסט מודגש**, *טקסט נטוי*, `קוד` וקישור [MEGA](https://mega.io).
        שורה שנייה אחרי מעבר שורה.
        """)
    write(p + "persian-and-urdu.md", """
        این یک پاراگراف فارسی با **متن پررنگ** است.

        یہ اردو میں ایک پیراگراف ہے جس میں *ترچھا متن* ہے۔
        """)
    write(p + "mixed-rtl-and-ltr-in-one-line.md", """
        English text then عربي text then English again.

        עברית with English words and numbers 123 and 456 inside.

        A file name ملف.md and a path /folder/مجلد/file.
        """)
    write(p + "rtl-lists-and-tasks.md", """
        - عنصر أول
        - عنصر ثان
          - عنصر متداخل

        1. פריט ראשון
        2. פריט שני

        - [ ] مهمة مفتوحة
        - [x] משימה שהושלמה
        """)
    write(p + "rtl-table.md", """
        | الاسم | الحجم | النوع |
        |:------|------:|:-----:|
        | ملف | 12 | نص |
        | שם | 34 | תמונה |
        """)
    write(p + "rtl-quote-code-heading.md", """
        ## כותרת משנה

        > اقتباس باللغة العربية مع **نص عريض**.

        ```
        // code stays left to right
        let name = "اسم"
        ```
        """)


def unicode_and_emoji():
    p = "unicode-and-emoji/"
    write_bytes(p + "accents-cjk-emoji-mixed.md", fixture("parity/v-18-unicode-lines.md"))
    write(p + "accents-and-umlauts.md", """
        Café, naïve, Zürich, São Paulo, Ærøskøbing, Łódź, İstanbul, Ελληνικά, Русский текст.

        **Ünïcödé bold** and *ñandú italic*.
        """)
    write(p + "chinese-japanese-korean.md", """
        # 中文标题

        这是一个中文段落，包含**粗体**和*斜体*以及`代码`。

        日本語の段落です。**太字**と*斜体*があります。

        한국어 문단입니다. **굵게** 그리고 *기울임*.
        """)
    write(p + "emoji-zwj-flags-skin-tones.md", """
        Family 👨‍👩‍👧‍👦, flags 🇳🇿 🇯🇵 🇧🇷, skin tones 👍🏻 👍🏿, keycaps 1️⃣ #️⃣, new emoji 🫠 🪿.

        **Bold 🚀** *italic 🎉* `code 💾` ~~strike 🗑️~~

        # Heading 🔥

        - [x] Done ✅
        """)
    write(p + "combining-marks-and-zalgo.md", """
        Combining: é ä ñ (decomposed forms).

        Stacked: Z͓͑͒a͔͕͖l͗͘g͙o͚.
        """)
    write(p + "zero-width-and-nbsp.md",
          "Zero​width​space, non breaking space, word⁠joiner, soft­hyphen.\n\n"
          "Narrow no-break space and em space.\n", dedent=False)
    write(p + "thai-devanagari-and-other-scripts.md", """
        ภาษาไทยไม่มีช่องว่างระหว่างคำ ซึ่งทำให้การตัดบรรทัดยาก

        हिन्दी में एक अनुच्छेद **मोटे अक्षरों** के साथ।

        ქართული ენა, Հայերեն, አማርኛ, ᏣᎳᎩ.
        """)
    write(p + "math-and-symbols.md", """
        ∑ ∫ √ ∞ ≠ ≤ ≥ ± × ÷ → ← ↔ ∀ ∃ ∈ ∉ ⊂ ⊃ ∪ ∩ α β γ δ π Ω

        Box drawing: ┌─┬─┐ │ │ │ └─┴─┘
        """)
    write_bytes(p + "null-character-replaced.md", b"Text with a NUL \x00 character.\n\nAnd another\x00here.\n")
    write_bytes(p + "object-replacement-character-in-text.md",
                "Text with an object replacement character ￼ in it.\n\n![￼x](u.png)\n".encode("utf-8"))
    write_bytes(p + "invalid-utf8-bytes.md", b"Valid text, then invalid bytes: \xff\xfe\xc3 and more text.\n")


def line_endings():
    p = "line-endings/"
    all_blocks = fixture("all-blocks.md").decode("utf-8")
    write(p + "crlf-all-blocks.md", all_blocks, dedent=False, newline="\r\n")
    write(p + "lone-cr-all-blocks.md", all_blocks, dedent=False, newline="\r")
    write_bytes(p + "crlf-short.md", fixture("parity/n-04-crlf.md"))
    write_bytes(p + "lone-cr-short.md", fixture("parity/n-05-lone-cr.md"))
    write_bytes(p + "mixed-lf-crlf-cr.md",
                b"# Mixed line ends\n\nLF line\r\nCRLF line\rCR line\n\n- a\r\n- b\r- c\n\n```\r\ncode\r\n```\r\n")
    write_bytes(p + "no-final-newline.md", b"# Heading\n\nThe last line has no newline")
    write_bytes(p + "crlf-hard-breaks-and-code.md",
                b"hard  \r\nbreak and\\\r\nbackslash\r\n\r\n```\r\nline 1\r\nline 2\r\n```\r\n")
    write_bytes(p + "tabs-as-indentation.md", fixture("parity/v-30-tabs.md"))
    write_bytes(p + "utf8-byte-order-mark.md", "﻿# Heading after a BOM\n\nText.\n".encode("utf-8"))


def edge_cases():
    p = "edge-cases/"
    write_bytes(p + "empty-file.md", b"")
    write_bytes(p + "whitespace-only.md", b"   \n\t\n  \n")
    write_bytes(p + "blank-lines-only.md", fixture("parity/n-20-blank-lines.md"))
    write_bytes(p + "empty-constructs.md", fixture("parity/n-21-empty-constructs.md"))
    write_bytes(p + "depth-quotes-and-lists.md", fixture("parity/n-10-depth.md"))
    write_bytes(p + "setext-edge-cases.md", fixture("parity/e-03-setext.md"))
    write_bytes(p + "gfm-mix.md", fixture("parity/e-05-gfm.md"))
    write_bytes(p + "code-and-comment.md", fixture("parity/e-06-code-and-comment.md"))
    write_bytes(p + "unclosed-underline-tag-with-bold.md", fixture("parity/v-29-trailing-hash-html.md"))
    write_bytes(p + "backslash-hard-break-at-end.md", fixture("parity/v-32-backslash-hardbreak-end.md"))
    write_bytes(p + "emphasis-edge.md", fixture("parity/v-23-emph-edge.md"))
    write(p + "inline-tag-and-image-cases.md", _strip_heading(fixture("parity/n-23-review-inline.md"),
                                                              "# Inline tag and image cases"), dedent=False)
    write(p + "task-marker-and-image-cases.md", _strip_heading(fixture("parity/n-24-review-differences.md"),
                                                               "# Task marker and image cases"), dedent=False)
    write_bytes(p + "mixed-blocks-100kb.md", fixture("parity/c-mixed-100k.md"))
    write(p + "long-line-no-spaces-100k-chars.md",
          "Known limit: a seam remains without newlines.\n\n" + "x" * 100_000 + "\n", dedent=False)
    write(p + "long-word-in-paragraph.md",
          "Before " + "Supercalifragilistic" * 200 + " after.\n", dedent=False)
    write(p + "deeply-nested-quotes-100.md", "> " * 100 + "one hundred levels\n", dedent=False)
    write(p + "deeply-nested-lists-100.md", "".join("  " * i + f"- level {i}\n" for i in range(100)), dedent=False)
    write(p + "deeply-nested-emphasis.md", "*a **b *c **d *e **f** e* d** c* b** a*\n", dedent=False)
    huge = "edge-cases/huge-single-blocks/"
    write(huge + "paragraph-1mb.md",
          "Words of a very long paragraph with **bold** text. " * 20_000 + "\n", dedent=False)
    # One paragraph: a soft line break every 200 characters and no blank line.
    line = ("Words of one long paragraph that has a soft line break after every two hundred characters. " * 3)[:199]
    write(huge + "paragraph-1mb-with-line-breaks.md",
          "\n".join(f"{i:05d} {line}"[:200] for i in range(1_048_576 // 201)) + "\n", dedent=False)
    write(huge + "code-block-5mb.md",
          "```text\n" + "\n".join(f"let line{i} = {i}" for i in range(250_000)) + "\n```\n", dedent=False)
    write(huge + "table-100k-rows.md", "| Row | Value | Note |\n|---|:-:|--:|\n" +
          "\n".join(f"| {i} | v{i} | `n` |" for i in range(100_000)) + "\n", dedent=False)
    write(huge + "list-100k-items.md", "\n".join(f"- item {i}" for i in range(100_000)) + "\n", dedent=False)
    write(huge + "quote-1mb.md",
          "\n".join(f"> Quoted paragraph {i} with some words in it.\n>" for i in range(20_000)) + "\n", dedent=False)
    write(huge + "line-1mb-no-spaces.md", "x" * 1_000_000 + "\n", dedent=False)
    for name, text in pathological_inputs():
        write("edge-cases/pathological/" + name + ".md", text, dedent=False)


SELECTION_STEPS = """
> **Steps to try** (Edit mode, rich text):
>
> 1. Long-press a word, then tap Select All. The selection covers every row.
> 2. Long-press a word, then drag a handle out of its row, up and down over other rows.
> 3. With a hardware keyboard: put the caret in a row, then press Shift+Down and Shift+Up across rows.
> 4. Select over rows, tap Copy, place the caret elsewhere and Paste.
> 5. Select over rows, tap Cut, then Undo. The text comes back.
> 6. Tap inside a selection: the edit menu shows. Tap outside: a caret shows. Swipe outside a handle: the list scrolls.
"""


def selection_file(name, case, body):
    """Writes one selection test file: what the case is, the shared steps, then the content."""
    write("editing/selection/" + name, "# " + case + "\n" + SELECTION_STEPS + "\n" + textwrap.dedent(body).lstrip("\n"),
          dedent=False)


def editing():
    selection_file("paragraphs-several.md", "Selection over several paragraphs", """
        The first paragraph has a few sentences. Select from here into the next paragraphs.
        It goes on after a soft line break.

        The second paragraph has **bold**, *italic*, `code` and a [link](https://mega.io).

        The third paragraph is longer. It wraps over several lines on a phone, so the selection handle moves over
        wrapped lines inside one row before it leaves the row and enters the next one.

        The fourth paragraph ends the file.
        """)
    selection_file("mixed-blocks.md", "Selection over headings, lists, quotes, checkboxes and dividers", """
        ## A heading

        A paragraph before the list.

        - Bullet one
        - Bullet two
          - Nested bullet

        1. Ordered one
        2. Ordered two

        - [ ] Open task
        - [x] Done task

        > A quote with *emphasis*.
        >
        > A second quote paragraph.

        ---

        ### Another heading

        A paragraph after the divider.
        """)
    selection_file("code-block-between-paragraphs.md", "Selection over a code block", """
        A paragraph before the code block. Start the selection here.

        ```swift
        let greeting = "Hello"
        print(greeting)
        ```

        A paragraph after the code block. End the selection here.
        """)
    selection_file("table-atomic-block.md", "Selection over a table (atomic block)", """
        The table below is one block. A selection takes all of it or none of it.

        | Name | Size | Type |
        |:-----|-----:|:----:|
        | notes.md | 12 KB | Text |
        | photo.jpg | 3.4 MB | Image |

        A paragraph after the table. Drag the handle from here up over the table.
        """)
    selection_file("right-to-left-hebrew.md", "Selection in a right-to-left document (Hebrew)", """
        זוהי פסקה ראשונה בעברית. בחרו מכאן אל הפסקאות הבאות.

        פסקה שנייה עם **טקסט מודגש** ו*טקסט נטוי*.

        - פריט ראשון
        - פריט שני

        > ציטוט בעברית.

        פסקה אחרונה בקובץ.
        """)
    selection_file("mixed-direction.md", "Selection in mixed-direction text", """
        iOS שלום and back to English in one line.

        שלום iOS שלום, a line that starts in Hebrew.

        - Item with עברית inside
        - פריט with English inside

        English paragraph at the end.
        """)
    # Just under the 500,000-character rich-mode limit, with short blocks, for autoscroll tests.
    section = ("## Section {n}\n\nA paragraph of section {n} with enough words to wrap over two lines on a phone screen.\n\n"
               "- First item of section {n}\n- Second item of section {n}\n\n")
    parts = []
    size = 0
    n = 1
    while True:
        part = section.format(n=n)
        if size + len(part) > 490_000:
            break
        parts.append(part)
        size += len(part)
        n += 1
    selection_file("long-document-near-limit.md", "Autoscroll in a long document (about 490,000 characters)",
                   "Drag a handle to the top or bottom edge of the screen. The list scrolls by itself.\n\n" + "".join(parts))


PREVIEW_SELECTION_STEPS = """
> **Steps to try** (Preview mode). The preview selects whole blocks:
>
> 1. Long-press a block. The whole block is selected.
> 2. Drag the bottom handle down. The selection grows one block at a time. Drag the top handle up too.
> 3. Drag a handle to the top or bottom edge of the screen. The list scrolls by itself.
> 4. Tap Copy, then paste in Notes. The text is plain, with no Markdown symbols.
> 5. Tap outside the selection. The selection ends.
"""


def preview_selection_file(name, case, body):
    """Writes one preview selection test file: what the case is, the shared steps, then the content."""
    write("preview/selection/" + name, "# " + case + "\n" + PREVIEW_SELECTION_STEPS + "\n" + body, dedent=False)


def preview_selection():
    preview_selection_file("mixed-blocks.md", "Block selection over mixed blocks", textwrap.dedent("""
        ## A heading

        A paragraph with **bold**, *italic*, `code` and a [link](https://mega.io).

        - Bullet one
        - Bullet two

        1. Ordered one
        2. Ordered two

        - [ ] Open task
        - [x] Done task

        > A quote.

        ```swift
        let value = 42
        ```

        | A | B |
        |---|---|
        | 1 | 2 |

        ---

        ![Wide image](../../images/local/assets/wide.png)

        The last paragraph.
        """).lstrip("\n"))
    preview_selection_file("long-list-300-items.md", "Block selection over a long list (autoscroll)",
                           "".join(f"- List item number {i + 1}\n" for i in range(300)))
    preview_selection_file("quote-with-children.md", "Block selection inside a quote with children", textwrap.dedent("""
        > A quote paragraph.
        >
        > - A list in the quote
        > - A second item
        >
        > > A nested quote.
        >
        > ```
        > code in the quote
        > ```
        >
        > The last quote paragraph.

        A paragraph after the quote.
        """).lstrip("\n"))
    preview_selection_file("big-code-block-and-table.md", "Block selection over a big code block and a big table",
                           "A paragraph before the code block.\n\n```text\n"
                           + "".join(f"code line {i + 1}\n" for i in range(400))
                           + "```\n\nA paragraph between them.\n\n| Row | Value |\n|---|---|\n"
                           + "".join(f"| {i + 1} | value {i + 1} |\n" for i in range(200))
                           + "\nA paragraph after the table.\n")
    preview_selection_file("right-to-left.md", "Block selection in right-to-left text", textwrap.dedent("""
        זוהי פסקה ראשונה בעברית.

        هذه فقرة باللغة العربية.

        - פריט ראשון
        - عنصر ثان

        > ציטוט בעברית.

        iOS שלום, a mixed line.
        """).lstrip("\n"))


def _strip_heading(data, heading):
    """Replaces the fixture heading and drops sentences that compare with an earlier parser."""
    lines = data.decode("utf-8").split("\n")
    text = heading + "\n" + "\n".join(lines[1:])
    return re.sub(r" The old parser[^.]*\.", "", text)


def pathological_inputs():
    """Inputs from cmark's test/pathological_tests.py, the same as BenchmarkDocuments.pathologicalInputs."""
    return [
        ("nested-strong-emph", "*a **a " * 65_000 + "b" + " a** a*" * 65_000),
        ("many-emph-closers-no-openers", "a_ " * 65_000),
        ("many-emph-openers-no-closers", "_a " * 65_000),
        ("many-link-closers-no-openers", "a]" * 65_000),
        ("many-link-openers-no-closers", "[a" * 65_000),
        ("mismatched-openers-and-closers", "*a_ " * 50_000),
        ("openers-and-closers-multiple-of-3", "a**b" + "c* " * 50_000),
        ("link-openers-and-emph-closers", "[ a_" * 50_000),
        ("nested-brackets", "[" * 50_000 + "a" + "]" * 50_000),
        ("deeply-nested-lists-1000", "".join("  " * i + "* a\n" for i in range(1_000))),
        ("backticks", "".join("e" + "`" * i for i in range(1, 5_000))),
        ("unclosed-links", "[a](<b" * 30_000),
        ("unclosed-html-comments", "</" + "<!--" * 300_000),
        ("many-image-openers", "![p" * 100_000 + "\n"),
    ]


# MARK: - Spec examples


def spec_examples(file_name, folder):
    """Writes each example of a cmark spec file as its own file, grouped by section."""
    fence = "`" * 32
    section = "start"
    number = 0
    in_example = False
    lines = []
    with open(os.path.join(FIXTURES, "cmark-spec", file_name), encoding="utf-8") as f:
        for line in f.read().split("\n"):
            if line.startswith(fence + " example"):
                in_example, lines = True, []
                continue
            if in_example:
                # The Markdown ends at ".". The expected HTML follows until the closing fence.
                if line.startswith(fence):
                    in_example = False
                elif line == "." and lines is not None:
                    number += 1
                    text = "\n".join(lines).replace("→", "\t")
                    write(f"{folder}/{section}/example-{number:03d}.md", text + ("\n" if lines else ""), dedent=False)
                    lines = None
                elif lines is not None:
                    lines.append(line)
                continue
            match = re.match(r"^#{1,2} (.+)$", line)
            if match:
                section = re.sub(r"[^a-z0-9]+", "-", match.group(1).lower()).strip("-")


def large_files():
    p = "large-files/"
    section = textwrap.dedent("""
        ## Section heading

        A paragraph with **bold**, *italic*, `code`, ~~strike~~ and a [link](https://mega.io).
        It continues on a second line so there is a soft break.

        - item one
        - item two
          - nested item
        1. first
        2. second

        > A quote with *emphasis*.

        ```swift
        let value = 42
        print(value)
        ```

        | A | B |
        |---|:-:|
        | 1 | 2 |

        ---


        """).lstrip("\n")
    # The 95 MB file stays under GitHub's 100 MB file limit and under MarkdownPreview.sizeLimitInBytes.
    for mb in (2, 10, 50, 95):
        write(p + f"mixed-sections-{mb}mb.md", varied_sections(mb * 1024 * 1024), dedent=False)
    # Just over MarkdownPreview.sizeLimitInBytes (100 MiB). The demo checks the file size and shows the message.
    target = 100 * 1024 * 1024 + 1024 * 1024
    write(p + "too-large-101mib-over-limit.md", section * (target // len(section.encode()) + 1), dedent=False)


WORDS = (
    "cloud drive folder file share link backup sync photo video album upload download transfer quota storage "
    "account device contact chat meeting note text table code block list item quote heading paragraph line "
    "secure private encrypted fast simple large small quick slow first last next other every each some many "
    "open close move copy rename delete restore save keep show hide read write check select scroll tap"
).split()


def varied_sections(target):
    """Sections that differ in text, kind and size, so no two rows have the same content or height."""
    rng = random.Random(12683)
    parts = []
    size = 0
    number = 0

    def words(low, high):
        return " ".join(rng.choice(WORDS) for _ in range(rng.randint(low, high)))

    def sentence():
        text = words(3, 18)
        style = rng.random()
        if style < 0.15:
            text = text.replace(" ", " **", 1) + "**"
        elif style < 0.25:
            text += f" `{rng.choice(WORDS)}()`"
        elif style < 0.32:
            text += f" [{rng.choice(WORDS)}](https://mega.io/{rng.choice(WORDS)})"
        return text[0].upper() + text[1:] + "."

    def paragraph():
        return " ".join(sentence() for _ in range(rng.randint(1, 14)))

    def bullet_list():
        lines = []
        task = rng.random() < 0.3
        ordered = not task and rng.random() < 0.4
        for index in range(rng.randint(1, 12)):
            marker = f"{index + 1}." if ordered else ("- [x]" if task and rng.random() < 0.5 else "- [ ]" if task else "-")
            lines.append(f"{marker} {' '.join(sentence() for _ in range(rng.randint(1, 4)))}")
            if not ordered and rng.random() < 0.2:
                lines.append(f"  - {sentence()}")
        return "\n".join(lines)

    def quote():
        return "\n>\n".join("> " + paragraph() for _ in range(rng.randint(1, 3)))

    def code():
        lines = [f"let {rng.choice(WORDS)}{i} = \"{words(1, rng.choice((3, 12, 30)))}\"" for i in range(rng.randint(1, 40))]
        return "```swift\n" + "\n".join(lines) + "\n```"

    def table():
        columns = rng.randint(2, 6)
        rows = [" | ".join(words(1, 6) for _ in range(columns)) for _ in range(rng.randint(1, 15))]
        header = " | ".join(words(1, 2) for _ in range(columns))
        return "\n".join([f"| {header} |", "|" + "---|" * columns] + [f"| {row} |" for row in rows])

    kinds = [paragraph, paragraph, paragraph, bullet_list, quote, code, table]
    while size < target:
        number += 1
        blocks = [f"{'#' * rng.randint(1, 4)} {number}. {words(2, 10)}"]
        blocks += [rng.choice(kinds)() for _ in range(rng.randint(1, 6))]
        if rng.random() < 0.15:
            blocks.append("---")
        part = "\n\n".join(blocks) + "\n\n"
        parts.append(part)
        size += len(part.encode())
    return "".join(parts)


def fixed_case_file(name, case, steps, body):
    """Writes one test file for a fixed bug: what the case is, the steps, what to expect, then the content."""
    text = "# " + case + "\n\n" + textwrap.dedent(steps).strip("\n") + "\n\n" + textwrap.dedent(body).lstrip("\n")
    write("fixed-cases/" + name, text, dedent=False)


def fixed_cases():
    fixed_case_file("indented-table-after-list-item.md", "Indented table and HTML block after a list item", """
        > **Steps** (Edit mode, rich text): put the caret in "Turn this line into a bullet" and tap the Bulleted list button.
        > Do the same for the second line. Show the source, then go back to rich text.
        >
        > **Expected:** the table and the HTML block stay outside the lists. The bullets stay editable.
        """, """
        Turn this line into a bullet

          | Name | Size |
          | --- | --- |
          | a.txt | 1 KB |

        Turn this line into a bullet too

          <div>
            An HTML block
          </div>
        """)
    fixed_case_file("copied-bullets-that-start-deeper.md", "Copied bullet rows that start deeper", """
        > **Steps** (Edit mode, rich text): select from `c` to `d`, copy, then paste after "Paste here:".
        > Do it again from `c` to `e`. Show the source.
        >
        > **Expected:** the pasted rows are siblings. `d` and `e` do not nest under `c`.
        """, """
        - a
          - b
            - c
          - d
        - e

        Paste here:
        """)
    fixed_case_file("copied-ordered-rows-that-start-deeper.md", "Copied ordered rows that start deeper", """
        > **Steps** (Edit mode, rich text): select from `c` to `d`, copy, then paste after "Paste here:". Show the source.
        >
        > **Expected:** `1. c` and `2. d` are one list. No `2) d` that starts a second list.
        """, """
        1. a
           1. b
              1. c
           2. d

        Paste here:
        """)
    fixed_case_file("code-part-pasted-into-text.md", "A part of a code block pasted into text", """
        > **Steps** (Edit mode, rich text): select `a*b*c` inside the code block, copy, then paste after "Paste here:".
        > Do the same with `<!-- x`. Leave the editor and open the file again.
        >
        > **Expected:** the pasted text shows the same characters. The asterisks stay.
        > `<!-- x` does not hide the rest of the file.
        """, """
        ```text
        let a = a*b*c
        let html = "<!-- x"
        ```

        Paste here:

        The last paragraph must still show after a save.
        """)
    fixed_case_file("code-part-pasted-into-source-mode.md", "A part of a code block pasted into source mode", """
        > **Steps:** in rich text, select `x_y_z` inside the code block and copy. Switch to the source editor.
        > Paste inside the empty code fence.
        >
        > **Expected:** the fence holds `x_y_z` with no backslashes.
        """, """
        ```text
        let name = x_y_z
        ```

        Paste inside this fence:

        ```text

        ```
        """)
    fixed_case_file("front-matter-typing.md", "Typing at the front matter", """
        > **Steps** (Edit mode, rich text): tap the front matter block so it is selected, type a word and press Enter.
        > Show the source.
        >
        > **Expected:** the front matter stays the first block. The new text goes after it.
        """, """
        ---
        title: Front matter
        tags: [test]
        ---

        The first paragraph after the front matter.
        """)
    fixed_case_file("link-typing-and-link-button.md", "Typing after a link and the Link button", """
        > **Steps** (Edit mode, rich text): put the caret right after the link and type a word.
        > Then tap inside the link text.
        >
        > **Expected:** the typed word is plain text, not part of the link.
        > With the caret inside the link, the Link button in the toolbar is on.
        """, """
        Open [the MEGA website](https://mega.io) here
        """)
    fixed_case_file("rich-copy-pasted-into-source-mode.md", "A rich copy pasted in source mode", """
        > **Steps:** in rich text, select from "Bold" to "second item" and copy. Switch to the source editor.
        > Paste after "Paste here:".
        >
        > **Expected:** the paste keeps its Markdown: `**bold**`, `*italic*` and the `-` markers.
        """, """
        **Bold** and *italic* text.

        - first item
        - second item

        Paste here:
        """)
    rows = "\n\n".join(f"Row {i}: a paragraph that stays short." if i % 3 == 0 else
                       f"- Bullet row {i}" if i % 3 == 1 else f"- [ ] Task row {i}" for i in range(30))
    long_task = "- [ ] " + " ".join(["A long task that wraps over many lines on a phone."] * 8)
    fixed_case_file("fast-scroll-reused-rows.md", "Fast scroll to the end in rich text", """
        > **Steps** (Edit mode, rich text): fling to the end of the file, then scroll back up and down.
        >
        > **Expected:** each row has the height of its own text. No row draws over the next one.
        """, rows + "\n\n" + "\n".join([long_task] * 4) + "\n")
    fixed_case_file("paste-that-adds-rows.md", "A paste that adds rows", """
        > **Steps** (Edit mode, rich text): select "Row 1" to "Row 5" and copy.
        > Put the caret at the end of "Row 10" and paste. Scroll down.
        >
        > **Expected:** each row below the paste shows its own text, at the right height.
        """, "\n\n".join(f"Row {i}" + (": " + " ".join(["a longer row that wraps."] * 6) if i % 4 == 0 else "")
                         for i in range(1, 61)) + "\n")
    wrapped = "\n\n".join(f"Paragraph {i}. " + " ".join(["This paragraph wraps over several lines on a phone"
                                                         " and over fewer lines in landscape."] * 6) +
                          f" It has `inline code number {i}` in it." for i in range(1, 41))
    fixed_case_file("rotation-wrapped-rows.md", "Rotation with tall wrapped rows", """
        > **Steps** (Preview and Edit mode): scroll to the middle so a paragraph is cut by the top edge.
        > Rotate a few times. Then scroll to the end and rotate a few times.
        >
        > **Expected:** the same line stays at the top after each rotation. At the end, the end stays on screen.
        > Rows with inline code draw at the full width, not as one clipped line.
        >
        > For source mode, open `large-files/mixed-sections-50mb.md` in the source editor and rotate.
        > The screen stays responsive.
        """, wrapped + "\n")
    fixed_case_file("text-size-change.md", "Row heights after a text size change", """
        > **Steps** (Preview and Edit mode): open the file, then change the text size in Settings or Control Center.
        > Turn Bold Text on and off too. Come back to the app.
        >
        > **Expected:** each row fits its text at the new size. No text is clipped or overlaps.
        """, """
        # A heading

        A paragraph with `inline code` and **bold** text. It wraps over two or three lines on a phone.

        - A bullet with `code`
        - [ ] A task

        > A quote that wraps over more than one line on a phone screen.
        """)


def readme():
    write("README.md", """
        # MEGAMarkdown test files

        Each file name says what the case is. Folders group the cases by topic.

        - `overview`: start here. Two short files that show every block kind.
        - `commonmark-spec` and `gfm-spec`: one file per example of the CommonMark and GFM specs.
          The number is the example number in the spec text.
        - `edge-cases/huge-single-blocks`: one block of 1 MB or more.
        - `large-files`: 2, 10, 50 and 95 MB documents with varied sections, and one file over the 100 MiB limit.
        - `editing/selection`: cases for the selection over rows in the editor. Each file lists the steps to try.
        - `preview/selection`: cases for the block selection in the preview. Each file lists the steps to try.
        - `fixed-cases`: one file per fixed bug. Each file lists the steps and what to expect.

        Relative links and images resolve against the folder of each file.
        Images show only their alt text unless the app loads them. The demo app loads local images,
        and remote images for the files in `images/remote`.
        """)


def main():
    global out
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    out = os.path.abspath(sys.argv[1])
    if os.path.exists(out):
        shutil.rmtree(out)
    os.makedirs(out)
    readme()
    overview()
    headings()
    paragraphs_and_breaks()
    emphasis()
    links()
    images()
    lists()
    task_lists()
    quotes()
    code()
    tables()
    html()
    footnotes_and_definitions()
    right_to_left()
    unicode_and_emoji()
    line_endings()
    edge_cases()
    editing()
    preview_selection()
    fixed_cases()
    spec_examples("spec.txt", "commonmark-spec")
    spec_examples("extensions.txt", "gfm-spec")
    if "--skip-large" not in sys.argv:
        large_files()
    for top in sorted(counts):
        print(f"{counts[top]:5d}  {top}")
    print(f"{sum(counts.values()):5d}  total")


if __name__ == "__main__":
    main()
