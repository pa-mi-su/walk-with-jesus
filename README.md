# Walk With Jesus

Walk With Jesus is a planned peaceful Catholic educational game and companion experience to [Sanctuary](https://mydailysanctuary.com). The first playable story will explore the Parable of the Good Samaritan through listening, practical choices, consequences, reflection, and a Scripture journal.

The project will use Godot 4.7.2 and GDScript, with one offline-first codebase targeting desktop, iPhone, iPad, and Android.

## Project status

Milestone 1 development. The project currently includes a responsive title screen and a small 2D isometric movement environment. The approved implementation sequence is documented in [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md).

No production Sanctuary services, credentials, accounts, analytics, advertising, or purchases are connected.

## Development

Contributor conventions, planned commands, religious-content safeguards, testing expectations, and the definition of done are in [AGENTS.md](AGENTS.md).

Install Godot 4.7.2 stable and its matching export templates, then open the repository folder in Godot or run it directly:

```sh
godot --editor --path .
godot --path .
```

On the title screen, choose **Begin the Journey**. Click or tap the road to move the placeholder traveler; desktop arrow keys are also supported.

Run the automated checks with:

```sh
godot --headless --path . --quit
godot --headless --path . -s res://tests/run_tests.gd
```

Behavior and responsive-layout checks are listed in [docs/MANUAL_TEST_CHECKLIST.md](docs/MANUAL_TEST_CHECKLIST.md).

## Content status

All prototype religious copy is provisional until it completes review for scriptural accuracy, Catholic teaching, pastoral tone, licensing, and age appropriateness. The prototype will use original summaries and Scripture references rather than unlicensed modern Bible translation quotations.

## License

No open-source license has been selected yet. All rights are reserved unless a file states otherwise.
