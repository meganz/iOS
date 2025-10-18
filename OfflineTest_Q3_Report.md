# Share / Manage Link Arabic Layout Review

## Symptoms
- When iOS is set to Arabic (RTL), the Share / Manage Link screen shows the filename text overlapping the thumbnail.
- Long filenames were unreadable and the cell became hard to tap because the label extended underneath the image.

## Root Cause
- The storyboard cell used a center-X constraint between the label stack and its container view. This forced the stack to stay centered even in RTL, so the intrinsic width of the labels pushed the stack under the thumbnail.
- Without explicit leading/trailing constraints, Auto Layout couldn’t adapt when the interface flipped directions.

## Fix Implemented
- Removed the `centerX` constraint and rely on the existing leading (to the thumbnail’s trailing anchor) and trailing (to the container) constraints. This keeps the text stack adjacent to the thumbnail in both LTR and RTL.
- No code changes were required; Auto Layout now respects the directional constraints Android uses to prevent overlap.

## Verification
- Build and run on a device or simulator configured for Arabic.
- Navigate to Share / Manage Link and confirm the filename stays to one side of the thumbnail with proper margin.
