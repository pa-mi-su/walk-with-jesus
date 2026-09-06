# Walk With Jesus

Walk With Jesus is a planned peaceful Catholic educational game and companion experience to [Sanctuary](https://mydailysanctuary.com). Each level is a self-contained journey with Jesus centered on a moment from His earthly life and ministry—such as a teaching, encounter, miracle, or sacred event. The prototype now contains two selectable levels: the Good Samaritan journey from Luke 10:25–37 and Jesus calming the storm from Mark 4:35–41.

The project will use Godot 4.7.2 and GDScript, with one offline-first codebase targeting desktop, iPhone, iPad, and Android.

## Project status

Milestone 2 development. A responsive journey-selection screen leads into either level after the player chooses one of four fictional travelers. Journey 1 follows Jesus along the Jericho road, includes scarce hidden provisions, factual Scripture questions, an early bread theft, and a later encounter where the same desperate traveler needs mercy. Journey 2 takes place aboard a first-century boat during a storm: the player secures the deck, bails water, crosses the boat to reach Jesus, and answers questions about Mark 4:35–41. Each journey ends with its own seal and results card. The approved implementation sequence is documented in [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md).

No production Sanctuary services, credentials, accounts, analytics, advertising, or purchases are connected.

## Development

Contributor conventions, planned commands, religious-content safeguards, testing expectations, and the definition of done are in [AGENTS.md](AGENTS.md).

Install Godot 4.7.2 stable and its matching export templates, then open the repository folder in Godot or run it directly:

```sh
godot --editor --path .
godot --path .
```

On the title screen, choose **Choose a journey**, select Journey 1 or Journey 2, then choose one of the four fictional travelers. Click or tap the environment to move; desktop arrow keys are also supported.

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
