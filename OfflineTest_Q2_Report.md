# MEGAAVViewController Playback Hang Investigation

## Symptoms
- Frequent Xcode Organizer hang reports pointing at `MEGAAVViewController.seekToDestinationAndPlay`.
- Main thread stack shows `AVPlayerViewController setPlayer:` executing during UIKit transition completion, leaving the UI unresponsive.

## Root Cause
- `seekToDestinationAndPlay` performed `AVPlayerItem(url:)`, metadata preparation, and `AVPlayer` creation synchronously on the main thread.
- When the URL referenced a streaming endpoint (local HTTP proxy), `AVPlayerItem` synchronously negotiated resource loading, blocking the run loop while UIKit still processed the transition completion callbacks.
- Because `AVPlayerViewController` expects main-thread exclusivity during transitions, the synchronous work created a self-reinforcing stall.

## Triggering Conditions
- Invoking resume playback from `viewDidAppear` or the resume alert while the presentation/dismissal transition is still winding down.
- Nodes that require HTTP streaming (folder links, remote videos) where the asset handshake is comparatively slow.
- Re-entrancy: repeated calls to `seekToDestinationAndPlay` (e.g. multiple alerts, quick dismiss) stacked synchronous work on the main queue.

## Mitigation Implemented
- Move player-item creation and initial seek to a background queue, only assigning the prepared player back on the main thread.
- Capture resume position data up front (before leaving the main thread) to stay within Core Data concurrency rules.
- Guard the completion with a per-invocation UUID token, window visibility checks, and URL equality to ignore stale or cancelled preparations.
- Reset the token inside `cancelPlayerProcess` so dismissals invalidate any in-flight setup work.

## Follow-up Recommendations
- Maintain the existing analytics/time-control observers to monitor regressions.
- Consider extending logging around preparation timing to confirm improvements in production.
