---
name: mega-camera-upload
description: >
  Camera Upload specialist — explains, refactors, debugs, and documents the MEGA
  iOS Camera Uploads feature. Use this skill whenever the user asks about camera
  uploads, including: navigating the code, implementing or refactoring upload
  flows, debugging upload progress or paused states, working with the upload
  queue or CoreData records, understanding the ObjC/Swift bridge, adding
  settings options, tracing background session recovery, or documenting the
  feature. Trigger terms: Camera Upload, CU, camera upload breakdown, upload
  queue, photo backup, video upload, upload progress, upload paused, BGRefresh,
  upload stats, HEIC conversion, PHAsset, upload session recovery,
  CameraUploadManager, CameraUploadOperation, CameraUploadTransferProgress.
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep
---

# Camera Upload Specialist

Deep expertise in the MEGA iOS Camera Uploads feature — analysis, explanation,
refactoring, performance, architecture, and documentation.

---

## When to Use This Skill

- Explaining Camera Upload code, classes, or functions
- Refactoring or improving performance of upload logic
- Breaking down architecture or async flows
- Identifying bottlenecks, memory issues, or concurrency risks
- Debugging stuck progress, paused state, or session recovery issues
- Adding new settings or preferences
- Creating documentation or flow diagrams

---

## Scope

Camera Uploads spans **all four Clean Architecture layers**. Never limit analysis
to `iMEGA/` alone — the domain logic, use cases, entities, and Swift repositories
live in `Modules/`.

**Primary directories:**

| Layer | Path |
|---|---|
| Domain (entities, use cases, protocols) | `Modules/Domain/MEGADomain/Sources/MEGADomain/{Entity,UseCase,RepositoryProtocol}/CameraUpload*/` |
| Swift repositories | `Modules/Repository/MEGARepo/Sources/MEGARepo/Repository/CameraUpload/` |
| Legacy ObjC repositories | `MEGAData/Repository/CameraUploads/` |
| Upload operations & managers | `iMEGA/Camera uploads/UploadOperations/`, `iMEGA/Camera uploads/UploadManagers/` |
| Transfer session & progress bridge | `iMEGA/Camera uploads/TransferSession/` |
| Upload utilities | `iMEGA/Camera uploads/UploadUtils/` |
| Progress & status UI | `iMEGA/Camera uploads/Progress/`, `iMEGA/Camera uploads/Status/`, `iMEGA/Camera uploads/Banner/` |
| Settings UI | `iMEGA/My Account/Settings/Camera Uploads/` |
| CoreData models | `iMEGA/Utils/CoreData/ManagedObjects/CameraUploads/` |

---

## Constraints

### Must Do
- Read the relevant reference file(s) before answering (see below)
- Validate reference information against actual current code — flag anything
  that looks outdated or inconsistent
- Suggest refactors that preserve existing behaviour unless explicitly told otherwise
- Keep ObjC types (`MOAssetUploadRecord`, `AssetUploadInfo`, `MEGASdk`) inside
  the repository layer — never let them escape to use cases or UI
- Draw independent conclusions; don't blindly trust references

### Must Not Do
- Modify unrelated modules or features
- Introduce breaking changes without explicit instruction
- Access repositories from use cases, or use MEGASdk outside the data layer
- Add `@MainActor` to domain-layer code
- Use `MEGASdkManager` — use `MEGASdk+SharedInstance` instead

---

## Reference Files

Read these as needed — don't load all upfront, only what the question touches:

| File | When to read |
|---|---|
| `references/architecture.md` | Module map, key types, layer rules, where to make changes |
| `references/flows.md` | Discovery, upload execution, progress→UI, state→banner, background recovery |
| `references/settings.md` | Preference keys, feature flags, concurrency config, file naming |
| `references/gotchas.md` | Known complexity, ObjC/Swift bridge rules, debugging checklist |

## Project Rules

Always read and apply these project-wide rules when suggesting answers, refactors, or new code:

| File | When to read |
|---|---|
| `.claude/rules/architecture.md` | Any suggestion involving layer boundaries, entities, use cases, repositories, or view models |
| `.claude/rules/code-style.md` | Any suggestion involving new or modified Swift code |
| `.claude/rules/swift-concurrency.md` | Any suggestion involving async/await, Tasks, actors, Sendable, or Combine |
