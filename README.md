# REACH

A native, private-by-default iPhone app for food logging, weight trends, deliberate calorie deficits, habit interruption and attention training. The interface uses navy, black, ivory ink artwork, condensed display lettering and Kufic Arabic. Native Liquid Glass is enabled on iOS 26 with a translucent material fallback on iOS 15–18.

## Features

- Portion-weight calorie and protein calculations; optional Open Food Facts search and camera barcode lookup.
- Mifflin–St Jeor resting energy estimates and activity-based TDEE, with clearly labeled uncertainty.
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

- [Mifflin–St Jeor study](https://pubmed.ncbi.nlm.nih.gov/2305711/)
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
