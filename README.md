# REACH

A native, private-by-default iPhone app for food logging, weight trends, deliberate calorie deficits, habit interruption and attention training. Version 1.1 uses solid black and navy surfaces, compact native typography, readable navigation and restrained ink artwork. Native Liquid Glass is limited to navigation and quote controls on iOS 26; older systems use solid surfaces. There are no decorative gradients, motivational dashboard posters or branding footers.

## Features

- Portion-weight calorie and protein calculations; optional Open Food Facts search and camera barcode lookup.
- Mifflin–St Jeor resting energy estimates, an editable home-and-gym activity plan, and workout logging. The plan adds weekly net exercise energy to a conventional sedentary baseline once, with clearly labeled uncertainty.
- Interactive charts for recorded weight, seven-day mean, logged calories, completed focus minutes and modeled caffeine clearance. Missing records remain missing rather than becoming invented zeroes.
- ABE Candy Ice Blast tracking by labeled servings or weighed powder, custom caffeine sources, dose timestamps, rolling 24-hour intake and estimated bedtime exposure. Current 12.5 g and older 10.5 g serving presets are editable against the user's tub.
- Intensive cut questionnaire, health screening, bounded deficits and weekly review guidance.
- Weight history and a two-week observed maintenance estimate requiring complete intake days.
- Four-step temptation interruption, breathing, grounding, environmental change and replacement action.
- Private check-in and setback journal with deletion controls.
- Progressive four-week attention practice, completed focus sessions and daily habits.
- More than 240 unique quotes, categories, favorites and sharing. Original writing is labeled separately from sourced quotations. Quran entries include Arabic, English meanings and verse links.
- Protected local JSON persistence, export and validated restore with a preserved pre-restore file.

## Build

On a Mac with Xcode 26 and XcodeGen:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Reach.xcodeproj -scheme Reach -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
```

GitHub Actions compiles the arm64 app, packages a sideloading IPA, runs fitness/quote/serialization checks, and performs simulator UI checks. IPA packaging does not supply Apple signing. Use an authorized sideloading signer such as Sideloadly or your development account to install. The iPhone deployment target is iOS 15.0.

## Limits and sources

Calorie values and expenditure are estimates, not laboratory measurements. The observed estimate assumes complete intake logging and uses a simplified 7,700 kcal/kg conversion; water and glycogen can skew it. The app does not diagnose addiction, treat ADHD, promise an instant brain reset or block other apps.

Home-and-gym TDEE uses resting energy × 1.2 plus `(MET − 1) × 3.5 × weight kg / 200 × session minutes × sessions per week / 7`. MET values come from the 2024 Adult Compendium. This convention does not measure an individual's energy expenditure. Existing activity settings remain in use until the user saves the new plan. An observed maintenance estimate requires 14 confirmed intake days and at least four distinct weigh-in dates in each of two weeks; it expires after 28 days.

Caffeine remaining is the sum of each logged dose × `0.5^(elapsed hours / half-life hours)`. The default five-hour half-life is editable and is an assumption, not a personal measurement. This elimination model assumes immediate availability and does not model absorption, blood concentration, other ABE stimulants or individual sensitivity. The chart's 3–7 hour shaded range illustrates sensitivity, not a confidence interval or a complete biological range. Neither a low estimate nor the FDA's general 400 mg/day adult reference guarantees safe use or sleep. The manufacturer states no more than one ABE serving daily.

## Updating from 1.0

Export a backup in settings, then install the replacement IPA over the existing app with the same signing account and bundle identity. Do not delete the installed app first. Version 1.1 keeps `app.reach.personal`, the existing `reach.json` journal, profile, meals, weigh-ins, check-ins and favorites. New fields are optional for compatibility with version 1.0 backups. Simulator screenshot data is synthetic and enabled only in Debug UI tests; release builds do not populate sample logs.

- [Mifflin–St Jeor study](https://pubmed.ncbi.nlm.nih.gov/2305711/)
- [2024 Adult Compendium, conditioning exercise](https://pacompendium.com/conditioning-exercise/)
- [Applied Nutrition ABE label](https://appliednutrition.uk/products/abe-all-black-everything-375g)
- [Older 315 g ABE label](https://connect.appliednutrition.uk/product/abe-all-black-everything-pre-workout-copy/)
- [FDA caffeine guidance](https://www.fda.gov/consumers/consumer-updates/spilling-beans-how-much-caffeine-too-much)
- [Caffeine pharmacokinetics study](https://pubmed.ncbi.nlm.nih.gov/6832208/)
- [National Academies caffeine reference](https://www.ncbi.nlm.nih.gov/books/NBK223808/)
- [CDC gradual weight-loss guidance](https://www.cdc.gov/healthy-weight-growth/losing-weight/index.html)
- [NIDDK Body Weight Planner](https://www.niddk.nih.gov/health-information/weight-management/body-weight-planner)
- [Mayo Clinic compulsive behavior treatment](https://www.mayoclinic.org/diseases-conditions/compulsive-sexual-behavior/diagnosis-treatment/drc-20360453)
- [NIH sleep recommendations](https://www.nhlbi.nih.gov/health/sleep/how-much-sleep)
- [Open Food Facts API documentation](https://openfoodfacts.github.io/openfoodfacts-server/api/tutorial-off-api/)
- [Quran.com](https://quran.com)
- [Epictetus, George Long translation](https://www.gutenberg.org/ebooks/10661)
- [Sun Tzu, Lionel Giles translation](https://www.gutenberg.org/files/132/132-h/132-h.htm)

Fonts: Bebas Neue and Reem Kufi, bundled with their SIL Open Font Licenses. Artwork generated with the built-in imagegen tool from a rough ivory tattoo-flash ink brief on flat midnight navy, with restrained cobalt accents. Original full-resolution assets are retained in `artwork/`.

No advertising, analytics or account system. Food lookups send a query or barcode to Open Food Facts; private journal entries are not sent. Device backups and exported files can contain sensitive information.
