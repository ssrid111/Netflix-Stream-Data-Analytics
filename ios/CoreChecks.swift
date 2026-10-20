import Foundation
@main struct CoreChecks {
 static func main() throws {
  let csv="title,type,release_year,country,listed_in\r\n\"A, \"\"quoted\"\"\nfilm\",Movie,2020,\"India, United States\",\"Drama, Drama\"\r\nInvalid,Movie,no,India,Drama"
  let rows=try CSVReader.catalog(csv)
  precondition(rows.count==1)
  precondition(rows[0].title=="A, \"quoted\"\nfilm")
  precondition(rows[0].countries.count==2)
  precondition(CatalogAnalytics.groups(rows,values:{$0.genreList})[0].count==1)
  do { _=try CSVReader.rows("\"unfinished");preconditionFailure("Invalid CSV accepted") } catch {}
  print("StreamLens CSV parsing, invalid-row filtering, and deduplicated genre checks passed")
 }
}
