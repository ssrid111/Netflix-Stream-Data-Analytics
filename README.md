# Netflix Stream Data Analytics — StreamLens

This project started as a notebook for exploring Netflix catalogue data. StreamLens turns that analysis into a dashboard you can actually use: import a CSV, filter the catalogue, and see how releases, genres, countries, and ratings compare.

## Versions

| Version | Branch | What it includes |
| --- | --- | --- |
| Original notebook | `main` | The existing `netflix.ipynb` exploration |
| Web dashboard v1 | `dashboard-web-v1` | Responsive dashboard, filters, CSV import and export |
| SwiftUI v2 | `swiftui-v2` | The web dashboard plus a native iPhone/iPad app in `ios/` |

[Open the web dashboard](https://streamlens-swetha.swetha-sangeetha2809.chatgpt.site) · [App portfolio](https://streamlens-swetha.swetha-sangeetha2809.chatgpt.site/portfolio.html)

## About the data

The notebook references `netflix_titles.csv` on Google Drive, but that CSV isn't in this repository. The dashboards include **48 clearly labeled invented sample titles** so you can preview them. Import your own catalogue CSV to work with real data.

These are catalogue statistics, not streaming engagement measurements. A list of titles doesn't tell us which titles were watched most or how long people watched.

## Run the web dashboard

```bash
python3 -m http.server 8000 --directory web/dist
```

Open **http://localhost:8000**. No dependency installation or build step is needed.

Choose **Import catalogue CSV** to load a UTF-8 file under 20 MB. It needs `title`, `type`, and `release_year` columns. Optional fields include `country`, `listed_in`, and `rating`. Type values should be `Movie` or `TV Show`. Invalid rows are skipped and counted.

You can search titles or genres, filter by country and year, switch between catalogue and trend views, and export your filtered selection. Imported files stay in the browser. Country and genre charts count a title in each listed category, so category totals can exceed the number of titles.

Run the analytics checks with:

```bash
node --test tests/analytics.test.cjs
```

## SwiftUI app

Switch to the `swiftui-v2` branch and open **ios/StreamLens.xcodeproj**. See `ios/README.md` there for details. It targets iOS 17+, uses Swift Charts, and imports catalogue CSV files on-device.

## What's next

- Test on physical iPhones and iPads.
- Add accessible chart summaries and larger-dataset performance checks.
- Add optional import persistence and release-date filters.

Independent portfolio project; not affiliated with Netflix. No App Store release or software license has been added yet.
