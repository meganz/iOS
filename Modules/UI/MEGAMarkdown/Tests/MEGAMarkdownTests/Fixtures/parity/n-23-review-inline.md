# Review 2 inline inputs that the old parser agrees with

An empty tag pair stays literal.

### <u></u>

1. <u></u>
2. second

<u></u>

An image with an empty URL is plain text.

![a]()

An object replacement character typed by the author stays in the alt text.

![￼x](u.png)

An image title is kept on the run.

![a](1.png "the title")
