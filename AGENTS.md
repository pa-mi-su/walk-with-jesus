# Walk With Jesus — Contributor Guide

## Project intent

Walk With Jesus is a peaceful, offline-first Catholic educational game and a companion experience to Sanctuary. The first playable story is the Parable of the Good Samaritan. The player controls a fictional disciple or traveler; the player never directly controls Jesus.

This repository targets Godot 4.7.2 stable with GDScript and a single project exported to desktop, iOS/iPadOS, and Android. Use the Compatibility renderer unless a measured requirement justifies a change; it supports the broadest mobile range and iOS simulator testing.

## Current phase

Planning only. Do not begin substantial implementation until the user approves `docs/IMPLEMENTATION_PLAN.md`.

The local folder must be initialized as a Git repository and connected to the user-approved GitHub repository before Milestone 1 implementation begins. Do not create a remote repository, choose its owner or visibility, overwrite an existing remote, or publish commits without confirming those choices with the user.

## Source control

- Use `main` as the stable default branch unless the connected GitHub repository already establishes another convention.
- Make focused commits with imperative summaries that describe one coherent change.
- Use short-lived feature branches for milestone work once collaboration or review requires them.
- Never commit `.godot/`, build/export output, local editor settings, OS metadata, signing materials, credentials, or production configuration. Maintain these exclusions in `.gitignore`.
- Before publishing, review the staged file list and scan for secrets and unexpectedly large binary files.
- Tag playable milestone snapshots only after their checks pass and the user accepts the milestone.

## Build and run commands

These commands become valid after Milestone 1 creates `project.godot`. Use a `godot` executable whose version is 4.7.2 stable.

```sh
godot --editor --path .
godot --path .
godot --headless --path . --quit
```

Planned debug exports, after export presets and templates exist:

```sh
godot --headless --path . --export-debug "macOS" build/macos/WalkWithJesus.app
godot --headless --path . --export-debug "Android" build/android/walk-with-jesus-debug.apk
godot --headless --path . --export-debug "iOS" build/ios/WalkWithJesus.xcodeproj
```

Never commit signing certificates, provisioning profiles, keystores, passwords, Apple team identifiers tied to an individual, API credentials, or production Sanctuary configuration.

## Testing

Run all checks available at the current milestone:

```sh
godot --headless --path . --quit
godot --headless --path . -s res://tests/run_tests.gd
```

The first command checks that the project imports and starts without engine errors. The second is the planned dependency-free GDScript test runner for content parsing, story transitions, virtue effects, save migrations, and deep-link parsing.

For behavior that is awkward to automate—touch movement, responsive layout, visual layering, external-link handoff, device rotation policy, suspend/resume, and export signing—follow `docs/MANUAL_TEST_CHECKLIST.md` once it is added. Test representative wide-phone, notched-phone, 4:3 tablet, Android, and iOS layouts before calling a milestone complete.

## Project conventions

- Use typed GDScript where it improves clarity and catches mistakes.
- Keep scenes focused and reusable. Prefer composition and signals over deep inheritance trees.
- Keep gameplay logic independent from UI nodes where practical so it can be tested headlessly.
- Treat story content as data. Dialogue, prompts, choices, outcomes, explanations, virtue changes, and Scripture references belong under `content/`, not scattered through scripts.
- Give every story, scene beat, choice, journal entry, and save schema a stable identifier. Never use display text as an identifier.
- Parse and validate content at load time. Fail with a specific content path and field name.
- Route local persistence through one save service. Version the save schema and write saves atomically.
- Route Sanctuary URLs and future deep links through an integration interface. Gameplay and UI must not call production services directly.
- Support mouse click and screen tap through the same movement intent. Keyboard movement may be included as a desktop accessibility/debug aid, but must not be required.
- Build responsive UI with anchors and `Container` nodes. Do not place critical UI at fixed phone-specific coordinates.
- Keep tap targets comfortably usable on phones and account for mobile safe areas.
- Use original geometric placeholders or assets whose license and attribution are recorded. Do not add copyrighted commercial game assets.
- Keep the MVP offline-first. The Sanctuary website button is the only planned network handoff and must fail gracefully when offline.

## Religious-content constraints

- Jesus is an NPC and is never directly player-controlled.
- Do not invent words for Jesus and present them as Scripture. For the prototype, prefer Scripture references and clearly labeled original summaries.
- Jesus' words and important actions must remain faithful to Scripture and Catholic teaching.
- Portray Jesus, biblical people, sacred events, suffering, and moral failure reverently; avoid mockery, trivialization, sensational violence, or reward language that reduces virtue to points alone.
- Mark unapproved religious copy as `provisional` in content data and UI/dev tooling where appropriate.
- Keep all religious copy replaceable without code changes.
- Do not include modern Bible translation quotations until their licensing status is confirmed. Track translation, source, quotation length, permission status, and required attribution for every direct quotation.
- Before release, require review for scriptural accuracy, Catholic teaching, pastoral tone, licensing, cultural/historical sensitivity, and age appropriateness.
- Player feedback should explain the teaching without claiming to judge the player's soul or moral worth.

## Definition of done

A change is done when all of the following that apply are true:

- It satisfies the approved milestone and preserves the separation between content, gameplay, presentation, persistence, and Sanctuary integration.
- The project opens and runs without Godot errors or new warnings that obscure real problems.
- Automated checks pass, and the relevant manual checklist items have been exercised.
- Mouse and touch-oriented interaction both work; UI remains usable at representative phone and tablet aspect ratios in landscape.
- New or changed story content passes schema validation and the religious-content review checklist.
- Save-data changes include a schema version and migration or an explicit compatibility decision.
- New third-party assets or dependencies have documented licenses and do not compromise offline play.
- Setup, test, export, and user-facing behavior documentation is updated.
- No secrets or production Sanctuary changes are included.
- The intended changes are committed to the connected GitHub repository, with no generated output or sensitive files tracked.

The first playable MVP additionally requires: new-game flow, tap/click movement, the teaching scene, the injured-traveler encounter, three virtue-affecting decisions, consequence and reflection feedback, an unlocked journal entry, persisted progress, a working Sanctuary website button, responsive phone/tablet layouts, and desktop/Android/iOS documentation.
