# StreamLens v2 — SwiftUI

This is a native iPhone and iPad companion to my Netflix catalogue dashboard. It turns a catalogue CSV into charts for release years, genres, countries, and content ratings.

## What's included

- SwiftUI navigation, search, and filters.
- Swift Charts bar charts and a ratings donut chart.
- Country, release-year, and Movie / TV Show filters.
- A CSV importer using the system Files picker, with quoted fields, escaped quotes, and multiline values.
- On-device analytics; imported files are not uploaded.
- A labeled sample of 48 invented titles for previewing the interface.

This is catalogue analytics. The dataset cannot tell us viewing popularity, hours watched, or Netflix user engagement. It is not affiliated with Netflix.

## Run it

Open `StreamLens.xcodeproj` in Xcode. Choose the StreamLens scheme and an iPhone simulator, then run it. The app targets iOS 17 and newer and supports iPhone and iPad.

For a physical device, choose your signing team and a unique bundle identifier.

## Import your dataset

Use **Import CSV** and choose a UTF-8 `netflix_titles.csv`-style file smaller than 20 MB. Required columns are `title`, `type`, and `release_year`. Optional columns are `country`, `listed_in`, `rating`, and `show_id`. Type values must be `Movie` or `TV Show`; invalid rows are skipped. All filters reset after import, and data stays in memory until the app closes.

The original notebook references a Google Drive CSV that isn't checked into this repository. The bundled sample is illustrative and is not extracted from that missing dataset.

## Core checks

From the repository root:

```bash
swiftc ios/StreamLens/Catalog.swift ios/CoreChecks.swift -o /tmp/streamlens-checks
/tmp/streamlens-checks
```

Checks cover quoted CSV fields, multiline titles, invalid rows, and deduplicated genre counts. The unsigned simulator target compiles; simulator interaction testing is unverified because the development machine's simulator runtime doesn't match its Xcode SDK.

This is not an App Store release. Device testing, an app icon, screenshots, a privacy policy, signing, and App Store review are still needed.
