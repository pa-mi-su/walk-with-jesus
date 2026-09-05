# Walk With Jesus — Initial Implementation Plan

Status: approved on September 5, 2026. Milestones 0 and 1 are complete; Milestone 2 awaits the next approval checkpoint.

## Architecture decision

Build the MVP as a 2D isometric game rather than a 3D game. In practical terms, the world is drawn with angled, tile-like artwork that suggests depth, while movement and collision remain on a flat 2D plane. This is a good fit for a small, peaceful scene, keeps mobile performance and asset production manageable, and makes click/tap movement straightforward.

Use Godot's Compatibility renderer for the widest mobile support and iOS simulator compatibility. Use a `CharacterBody2D` player guided by `NavigationAgent2D`; a click or tap selects a reachable destination and the navigation system supplies a path around obstacles.

The story will be a data-driven state machine: content data identifies the current beat and available choices; core logic applies consequences and advances to the next beat; presentation scenes render dialogue, choices, world cues, and journal updates. This allows later Gospel stories to reuse the same systems. A new journey begins with selection of an explicitly fictional player traveler. That character follows Jesus as a non-player guide through route and teaching triggers; the player never controls Jesus.

## Milestones

### 0. Repository and tool setup — complete

- Confirm the GitHub owner, repository name, and visibility.
- Initialize this folder as a Git repository with `main` as its default branch, or connect it safely if the user chooses an existing repository.
- Add a Godot-aware `.gitignore`, a concise README, and an initial planning commit.
- Create or connect the GitHub remote, push the initial commit, and verify that the local branch tracks the remote.
- Install Godot 4.7.2 stable and matching export templates.
- Configure Godot to use the installed OpenJDK 17 and the existing Android SDK; add missing Android components before Android export validation.

Approval checkpoint: verify the GitHub destination and confirm that only planning/setup files—not credentials or generated files—were published.

### 1. Playable foundation — complete

- Create the Godot 4.7.2 project and desktop-first run configuration.
- Add a responsive landscape title screen with “A Sanctuary Experience.”
- Create a small isometric test environment with original geometric placeholders.
- Add a controllable fictional traveler with unified click/tap destination movement and optional keyboard debug controls.
- Add camera bounds, collision/navigation, safe-area-aware UI, smoke checks, and desktop test instructions.
- Verify representative 16:9, 19.5:9, and 4:3 landscape viewports.
- Add a responsive startup character-selection step backed by external character data, and carry the selected fictional traveler into gameplay.

Approval checkpoint: confirm the 2D isometric movement feel and overall visual direction before story systems expand.

### 2. Teaching and choices

- Add content schemas and validation for story metadata, beats, speakers, summaries, choices, consequences, and references.
- Add reusable dialogue and choice presentation.
- Add Jesus as a reverently presented NPC and build the short, provisional teaching scene using an original summary plus Luke 10:25–37 references.
- Make Jesus the route-leading NPC: the selected traveler follows Him to teaching and encounter locations while Jesus remains outside player control.
- Add a story runner that emits presentation-neutral events.
- Test parsing, invalid content, branching, and deterministic state transitions.

Approval checkpoint: review the provisional religious content and choice framing.

### 3. Good Samaritan encounter

- Build the road encounter with the injured traveler and another traveler or villager.
- Add three meaningful decisions across the encounter.
- Add Charity and Mercy as understandable story feedback, not arcade scoring.
- Show immediate consequences, a short final reflection, and an unlocked Scripture journal entry.
- Add the completion screen and tune the path to approximately ten minutes.
- Test virtue effects, branches, completion, and journal unlock behavior.

### 4. Persistence and companion integration

- Add versioned, atomic local saves and resume/new-game behavior.
- Add Sanctuary branding configuration and a graceful external website handoff.
- Add an integration interface that parses but does not yet connect production deep links.
- Document proposed URI formats and future AWS-backed shared accounts, achievements, and daily-reading links without adding credentials or backend calls.
- Add Android and iOS export presets/documentation, a full manual checklist, and the religious-content review checklist.
- Validate desktop builds and all locally possible mobile export steps; clearly identify signing or physical-device checks that remain manual.

## Proposed folder structure

```text
.
├── AGENTS.md
├── project.godot
├── assets/
│   ├── audio/                 # Original or licensed ambience and effects
│   ├── fonts/                 # License-recorded fonts
│   ├── placeholders/          # Temporary original shapes and textures
│   └── ui/                    # Icons and theme imagery
├── autoload/
│   ├── game_state.gd          # Current session and virtue state
│   ├── save_service.gd        # Versioned local persistence
│   └── sanctuary_bridge.gd    # Website/deep-link boundary
├── content/
│   ├── schemas/               # Documented content shapes/validation fixtures
│   └── stories/
│       └── good_samaritan/    # Replaceable story, journal, and reference data
├── docs/
│   ├── IMPLEMENTATION_PLAN.md
│   ├── MANUAL_TEST_CHECKLIST.md
│   ├── CONTENT_REVIEW.md
│   ├── INTEGRATION.md
│   └── EXPORTING.md
├── scenes/
│   ├── app/                   # Boot and high-level flow
│   ├── characters/            # Player and NPC scene components
│   ├── story/                 # Dialogue, choice, reflection, journal views
│   ├── ui/                    # Shared responsive UI
│   └── world/                 # Isometric level and interactables
├── scripts/
│   ├── content/               # Loading and validation
│   ├── gameplay/              # Movement, interaction, virtues
│   ├── integration/           # Platform-neutral interfaces/adapters
│   └── story/                 # State machine and consequence application
└── tests/
    ├── fixtures/
    └── run_tests.gd           # Dependency-free headless test entry point
```

Generated imports, build output, export credentials, and local editor state will be ignored by Git.

## Assumptions

- The first scene uses fictional framing around the parable; it does not depict the player as changing the canonical events in Luke 10.
- “Isometric” means a 2D isometric presentation for the MVP, not a freely rotating 3D world.
- Godot 4.7.2 stable will be installed before implementation and its matching export templates before mobile export work.
- The Sanctuary wordmark, palette, fonts, and other protected brand assets can be supplied later. Milestone 1 will use a restrained placeholder visual system and the required text attribution.
- English is the only MVP language, but content and UI will avoid designs that prevent later localization.
- The game saves one local progress profile initially; cloud accounts are future work.
- Direct Bible quotations are excluded until translation rights are confirmed. Initial content is provisional original summary plus references.
- Apple signing identity, team ID, bundle identifiers, Android release keystore, store accounts, and physical test devices are not needed for the scaffold and will be supplied/configured only when export testing reaches that point.
- No backend, analytics, ads, in-app purchases, or modifications to Sanctuary production systems are in scope.
- The GitHub repository will use `main` as its default branch unless an existing repository dictates otherwise. Repository ownership and public/private visibility require explicit confirmation before creation.

## Decisions intentionally deferred

- Final art style, character appearance, and production asset pipeline.
- Final Sanctuary brand assets and exact color/font tokens.
- Licensed Bible translation and approved verbatim quotations.
- Minimum supported OS versions, final bundle identifiers, signing identities, and store metadata.
- Production deep-link association files, authentication, achievements, and AWS API contracts.
