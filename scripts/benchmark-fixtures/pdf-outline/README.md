# PDF outline benchmark fixtures

- Each PDF has 1,000 blank pages and 100, 1,000, 5,000, or 20,000 outline items.
- The three shapes are flat siblings, a chapter/section/subsection tree,
  and repeated chains of depth 10.
- Generate these PDFs on macOS because serializing the 20,000-item flat
  outline on an iOS simulator can overflow the stack.
- `scripts/benchmark.sh` compiles and runs the generator before the
  `MEGAPDFViewerBenchmarks` target builds; generated PDFs are ignored by Git.
