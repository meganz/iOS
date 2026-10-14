import Foundation
import MEGAFoundation

/// Limits of the preview parse. Tests pass small values.
struct PreviewParseLimits: Sendable {
    /// Bigger text (UTF-8 bytes) is not shown.
    var sizeLimitBytes = MarkdownPreview.sizeLimitInBytes
    var targetChunkBytes = MarkdownChunker.defaultTargetBytes
    /// A part of the text with no safe cut within this size is shown as plain text, with a notice above it.
    var maxChunkBytes = MarkdownChunker.defaultMaxChunkBytes
    /// Row weight for `PreviewRows.Builder`. 0 splits every block, so each list cell draws one short piece.
    var maxRowWeight = 0
    /// Runs on the parse thread after each batch, with the number of batches sent. Tests use it to hold the parse.
    var afterBatch: (@Sendable (Int) -> Void)?
}

/// New rows at the end of the preview, from one chunk of the text.
/// Rows only grow: a later batch never changes a row of an earlier batch.
struct PreviewBatch: Equatable, Sendable {
    var rows: [PreviewRow]
}

/// Turns Markdown into preview rows, one chunk after another, so the first rows show before the whole text is parsed.
enum PreviewPipeline {
    enum Outcome: Equatable, Sendable {
        /// Every chunk was sent.
        case complete
        /// The text is over `PreviewParseLimits.sizeLimitBytes`. No batch was sent.
        case tooLarge
        /// The task was cancelled. The batches sent before stay valid.
        case cancelled
    }

    enum Failure: Error, Equatable {
        /// The text is over `PreviewParseLimits.sizeLimitBytes`. No batch was sent.
        case tooLarge
        /// The parse task was cancelled. The batches sent before stay valid.
        case cancelled
    }

    /// One batch per chunk, parsed off the main actor. The stream ends normally when every chunk was sent.
    /// It throws `Failure`. Stopping the iteration cancels the parse.
    static func run(_ request: MarkdownParseRequest, limits: PreviewParseLimits) -> AsyncThrowingStream<PreviewBatch, any Error> {
        AsyncThrowingStream { continuation in
            // A plain `Task` in a nonisolated function runs off the main actor.
            let task = Task {
                switch parse(request, limits: limits, send: { continuation.yield($0) }) {
                case .complete: continuation.finish()
                case .tooLarge: continuation.finish(throwing: Failure.tooLarge)
                case .cancelled: continuation.finish(throwing: Failure.cancelled)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The chunk loop. It checks for cancellation before each chunk.
    /// Sends at least one batch unless the text is too large or the task is cancelled first.
    static func parse(_ request: MarkdownParseRequest, limits: PreviewParseLimits, send: (PreviewBatch) -> Void) -> Outcome {
        let byteCount = request.markdown.utf8.count
        guard byteCount <= limits.sizeLimitBytes else {
            MEGALog.log(
                level: .info,
                message: "[PreviewPipeline] Text over the size limit, not shown. bytes=\(byteCount) limit=\(limits.sizeLimitBytes)"
            )
            return .tooLarge
        }
        var source = request.markdown
        return source.withUTF8 { buffer in
            var chunker = MarkdownChunker(source: buffer, targetBytes: limits.targetChunkBytes, maxChunkBytes: limits.maxChunkBytes)
            // The gap below a row is set when the next row is added. So the last row of a batch waits for the next chunk.
            var carried: PreviewRow?
            var lastLine = 0
            var batchCount = 0
            while !Task.isCancelled {
                guard let chunk = chunker.next() else { return .complete }
                var builder = PreviewRows.Builder(maxWeight: limits.maxRowWeight)
                if let carried { builder.rows = [carried] }
                let body = UnsafeBufferPointer(rebasing: buffer[chunk.bytes])
                if chunk.isPlainText {
                    builder.appendPlainText(String(decoding: body, as: UTF8.self), firstLine: chunk.lines.lowerBound)
                } else {
                    lastLine = appendBlocks(of: chunk, body: body, chunker: chunker, softBreak: request.softBreak, lastLine: lastLine, to: &builder)
                }
                carried = chunker.isFinished ? nil : builder.rows.popLast()
                send(PreviewBatch(rows: builder.rows))
                batchCount += 1
                limits.afterBatch?(batchCount)
            }
            return .cancelled
        }
    }

    /// Parses one chunk with the link definitions known so far in front. Returns the line of its last block.
    private static func appendBlocks(
        of chunk: MarkdownChunker.Chunk,
        body: UnsafeBufferPointer<UInt8>,
        chunker: MarkdownChunker,
        softBreak: MarkdownSoftBreak,
        lastLine: Int,
        to builder: inout PreviewRows.Builder
    ) -> Int {
        let parsed = CmarkParser.blocks(
            prefix: chunker.definitionPrefix(for: chunk),
            body: body,
            softBreak: softBreak,
            lineOffset: chunk.lines.lowerBound - chunker.definitionLineCount(for: chunk),
            lastLine: lastLine
        )
        guard let parsed else {
            MEGALog.log(
                level: .warning,
                message: "[PreviewPipeline] cmark could not parse a chunk, showing raw text. "
                    + "line=\(chunk.lines.lowerBound) bytes=\(chunk.bytes.count)"
            )
            var text = InlineText()
            text.append(String(decoding: body, as: UTF8.self), style: [])
            builder.append(ParsedBlock(sourceLine: chunk.lines.lowerBound, kind: .paragraph(text)), decorations: [], gap: .block)
            return chunk.lines.lowerBound
        }
        for block in parsed.blocks {
            builder.append(block, decorations: [], gap: .block)
        }
        return parsed.lastLine
    }
}
