# Manual Test Checklist

Record the Godot version, operating system, device or simulator, viewport size, and result when running this checklist.

## Milestone 1 — Playable foundation

### Title and navigation

- [ ] Launching the project opens the title screen without an error dialog.
- [ ] The title reads “Walk With Jesus.”
- [ ] “A Sanctuary Experience” is clearly visible.
- [ ] “Begin the Journey” is reachable by mouse and keyboard focus.
- [ ] The title screen presents exactly one control that looks like a start action.
- [ ] The featured card clearly states what Jesus is doing or teaching in this journey.
- [ ] Activating the button opens character selection before the movement environment.
- [ ] Four fictional travelers are visible and selectable; Jesus is not a selectable character.
- [ ] Continue remains disabled until a traveler is chosen, then names the chosen traveler.
- [ ] The chosen traveler is the player-controlled person shown in the movement environment.
- [ ] The Title button returns to the title screen.

### Movement

- [ ] Clicking several reachable places moves the traveler toward each selected destination.
- [ ] Tapping several reachable places on a touch device or simulated touch input does the same.
- [ ] A destination marker gives immediate feedback at the selected location.
- [ ] Selecting a new destination while moving redirects the traveler cleanly.
- [ ] Arrow keys move the traveler during desktop testing.
- [ ] The traveler remains inside the playable area.
- [ ] Jesus is visibly separate from the player and cannot be controlled.
- [ ] When the traveler catches up, Jesus leads onward to the next road position.
- [ ] Clicking the Title button does not also move the traveler.

### Responsive landscape layout

- [ ] At 1280×720 (16:9), title text, illustration, and primary button fit without clipping.
- [ ] At 844×390 or a similar wide notched-phone landscape size, all critical controls remain visible and comfortably selectable.
- [ ] At 1024×768 (4:3 tablet landscape), the layout expands without awkward overlap or excessive empty gaps.
- [ ] No critical content sits beneath a simulated notch, rounded corner, or home indicator.
- [ ] Portrait rotation is not offered by mobile builds.

### Presentation and stability

- [ ] The isometric tiles form a readable, coherent ground plane.
- [ ] The road is visually distinct from the surrounding ground.
- [ ] The selected traveler and Jesus remain visually in front of the ground.
- [ ] Repeatedly moving between title and world does not duplicate UI, freeze input, or log errors.
- [ ] Suspending and resuming a desktop or mobile debug build does not break input.

## Later milestones

Dialogue, story branching, religious-content review, virtues, journal, saving, external links, deep links, and mobile export/signing checks will be added with their respective milestones.
