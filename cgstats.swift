#!/usr/bin/swift

import Foundation

// Functions

func processLineForWordCount(var line: String) -> String {
	if line.containsString("---") {
		line = ""
	}

	if line.containsString("###") {
		line = ""
	}

	if line.containsString(">") {
		line = line.stringByReplacingOccurrencesOfString(">", withString:"")
	}

	if line.containsString("[") || line.containsString("]") {
		line = line.stringByReplacingOccurrencesOfString("[", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")
	}

	if line.containsString("{{") {
		line = ""
	}

	if line.containsString("\\(") {
		line = line.stringByReplacingOccurrencesOfString("\\(", withString: "")
	}

	if line.containsString("\\)") {
		line = line.stringByReplacingOccurrencesOfString("\\)", withString: "")
	}

	if line.containsString("{%") {
		line = ""
	}

	while line.containsString("/reviews") || line.containsString("https:") || line.containsString("http:") {
		let sections = line.componentsSeparatedByString("(")
		for section in sections {
			if section.containsString("/reviews") || section.containsString("https:") || section.containsString("http:") {
				if let range = section.rangeOfString(")") {
					let replaceString = section.substringToIndex(range.startIndex)
					line = line.stringByReplacingOccurrencesOfString("(\(replaceString))", withString: "")
				}
			}
		}
	}

	// This has to happen after https:/http: or the line will be empty because of the :
	if line.containsString(":") {
		line = ""
	}

	line = line.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())

	return line
}

struct Post {
	var published: Bool
	var date: String
	var films: Int
	var title: String
	var rating: [Int]
	var country: [String]
	var language: [String]
	var year: [String]
	var ratio: [String]
	var words: Int
}

func readPost(filename: String) -> Post {
	var date: String = ""
	var published: Bool = true
	var films: Int = 0
	var title: String = ""
	var rating: [Int] = [Int]()
	var country: [String] = [String]()
	var language: [String] = [String]()
	var year: [String] = [String]()
	var ratio: [String] = [String]()
	var words: Int = 0

	let post = try! NSString(contentsOfURL: NSURL(fileURLWithPath: filename), encoding: NSUTF8StringEncoding)
	let lines = post.componentsSeparatedByString("\n")

	var wordCountLines = [String]()

	for line in lines {
		if line.hasPrefix("date:") {
			date = line.stringByReplacingOccurrencesOfString("date:", withString: "")
		}

		if line.hasPrefix("published:") {
			published = false
		}

		if line.containsString("rating:") || line.containsString("| rating") {
			films = films + 1

			var ratingString: String
			if line.hasPrefix("rating:") {
				ratingString = line.stringByReplacingOccurrencesOfString("rating:", withString: "")
			} else {
				ratingString = line.stringByReplacingOccurrencesOfString("{{ ", withString: "").stringByReplacingOccurrencesOfString(" | rating }}", withString: "")
			}
			ratingString = ratingString.stringByReplacingOccurrencesOfString(" ", withString:"")

			guard let ratingInt = Int(ratingString) else {
				continue
			}
			rating.append(ratingInt)
		}

		if line.hasPrefix("title:") {
			title = line.stringByReplacingOccurrencesOfString("title:", withString: "").stringByReplacingOccurrencesOfString("\"", withString: "")
			title = title.characters.split { $0 == " " }.map { String($0) }.joinWithSeparator(" ")
		}

		if line.hasPrefix("categories:") {
			let categoriesString = line.stringByReplacingOccurrencesOfString("categories: [", withString: "").stringByReplacingOccurrencesOfString("]", withString: "")
			let categories = categoriesString.componentsSeparatedByString(",")
			var foundYear = false
			var foundRatio = false

			for category in categories {
				if category.containsString("\"") {
					let possibleYear = category.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
					let actualYear: Int? = Int(possibleYear)

					if actualYear != nil {
						foundYear = true
						year.append(possibleYear)
					} else {
						foundRatio = true
						ratio.append(category.stringByReplacingOccurrencesOfString("\"", withString: "").stringByReplacingOccurrencesOfString(" ", withString: ""))
					}
				} else {
					if foundYear == false {
						country.append(category.characters.split { $0 == " " }.map { String($0) }.joinWithSeparator(" "))
					}

					if foundRatio == true {
						language.append(category.characters.split { $0 == " " }.map { String($0) }.joinWithSeparator(" "))
					}
				}
			}
		}

		wordCountLines.append(processLineForWordCount(line))
	}

	// To remove the aggregate rating from entries that have multiple films
	if films > 1 {
		films = films - 1

		// Special casing Fishing With John
		if title.containsString("Fishing with John") {
			films = 1
			rating = [rating[0], rating[0]]
		}

		rating.removeAtIndex(0)

		// Deal with the years when an entry might have multiple years
		var realYear = [String]()
		for line in lines {
			for individualYear in year {
				if line.containsString("(\(individualYear))") {
					realYear.append(individualYear)
				}

				if line.containsString("(\(individualYear)-") || line.containsString("-\(individualYear))") {
					realYear.append(individualYear)
				}
			}
		}

		if realYear.count >= 1 {
			year = realYear
		}

		if films != ratio.count && published {
			print("You need to manually add \(title), as it likely has multiple films with the same aspect ratio, and has thus been removed")
			ratio = [String]()
		}
	}

	for line in wordCountLines {
		if line.characters.count == 0 { continue }

		words += line.componentsSeparatedByString(" ").count
	}

	return Post(published: published, date: date, films: films, title: title, rating: rating, country: country, language: language, year: year, ratio:ratio, words: words)
}

func generatePostListForYear(year: String) -> [Post] {
	//let postsDir = "source/_posts"
	let postsDir = "/Users/arik/Development/danieltiger.github.io/source/_posts"
	let fileManager = NSFileManager.defaultManager()

	let filenames = try! fileManager.contentsOfDirectoryAtPath(postsDir)

	var posts = [Post]()
	for filename in filenames {
		if filename.containsString("-\(year)") { continue }

		let post = try! NSString(contentsOfURL: NSURL(fileURLWithPath: "\(postsDir)/\(filename)"), encoding: NSUTF8StringEncoding)
		let lines = post.componentsSeparatedByString("\n")

		var date = ""
		var published = true
		for line in lines {
			if line.hasPrefix("published:") {
				published = false
			}

			if line.hasPrefix("date:") {
				date = line.stringByReplacingOccurrencesOfString("date:", withString: "")

				if date.containsString(year) && published {
					posts.append(readPost("\(postsDir)/\(filename)"))
				}	
				
				continue
			}
		}
	}

	return posts
}

func generateRatingSplits(posts: [Post]) -> [[Post]] {
	var results = [[Post]]()
	results.append([Post]())
	results.append([Post]())
	results.append([Post]())
	results.append([Post]())
	results.append([Post]())

	for post in posts {
		for rating in post.rating {
			results[rating - 1].append(post)
		}
	}

	return results
}

func mostCommonRating(ratingSplits: [[Post]]) -> Int {
	let sortedSplits = ratingSplits.sort { $0.count > $1.count}
	for post in sortedSplits[0] {
		if post.rating.count == 1 {
			return post.rating[0]
		}
	}

	return 0
}

func lowestRatedFilms(ratingSplits: [[Post]]) -> [String] {
	let filteredArray = ratingSplits.filter { $0.count > 0 }
	return filteredArray[0].map { $0.title }
}

func lowestRating(ratingSplits: [[Post]]) -> Int {
	let filteredArray = ratingSplits.filter { $0.count > 0 }
	for post in filteredArray[0] {
		if post.rating.count == 1 {
			return post.rating[0]
		}
	}

	if filteredArray[0].count == 1 {
		return filteredArray[0][0].rating.sort { $0 < $1 }[0]
	}

	return 0
}

func generateCountrySplits(posts: [Post]) -> [String: [Post]] {
	var results = [String: [Post]]()

	for post in posts {
		for country in post.country {
			if results[country] == nil {
				results[country] = [Post]()
			}

			results[country]?.append(post)
		}
	}

	return results
}

func generateLanguageSplits(posts: [Post]) -> [String: [Post]] {
	var results = [String: [Post]]()

	for post in posts {
		for language in post.language {
			if results[language] == nil {
				results[language] = [Post]()
			}

			results[language]?.append(post)
		}
	}

	return results
}

func rankedCategorySplits(splits: [String: [Post]]) -> [String] {
	let sortedKeys = splits.keys.sort({ (firstKey, secondKey) -> Bool in
    	return splits[firstKey]!.count > splits[secondKey]!.count
    })
	var results = [String]()

	for key in sortedKeys {
		results.append("\(key): \(splits[key]!.count)")
	}

	return results
}

func generateYearSplits(posts: [Post]) -> [String: [Post]] {
	var results = [String: [Post]]()

	for post in posts {
		for year in post.year {
			if results[year] == nil {
				results[year] = [Post]()
			}

			results[year]?.append(post)
		}
	}

	return results
}

func calculateOldestYear(splits: [String: [Post]]) -> String {
	let sortedKeys = splits.keys.sort({ (firstKey, secondKey) -> Bool in
    	return Int(firstKey) < Int(secondKey)
    })

	return sortedKeys.first!
}

func calculateNewestYear(splits: [String: [Post]]) -> String {
	let sortedKeys = splits.keys.sort({ (firstKey, secondKey) -> Bool in
    	return Int(firstKey) < Int(secondKey)
    })

	return sortedKeys.last!
}

func decadeCounts(yearSplits: [String: [Post]]) -> [String] {
	var decades = [String: [String]]()
	for (year, posts) in yearSplits {
		let decade = "\(String(year.characters.dropLast()))0"

		if decades[decade] == nil {
			decades[decade] = [String]()
		}

		decades[decade]?.appendContentsOf(posts.map { $0.title })
	}

	var results = [String]()
	let sortedKeys = decades.keys.sort { (firstKey, secondKey) -> Bool in
		return Int(firstKey) < Int(secondKey)
	}

	for key in sortedKeys {
		results.append("\(key): \(decades[key]!.count)")
	}

	return results
}

func generateRatioSplits(posts: [Post]) -> [String: [Post]] {
	var results = [String: [Post]]()

	for post in posts {
		for ratio in post.ratio {
			if results[ratio] == nil {
				results[ratio] = [Post]()
			}

			results[ratio]?.append(post)
		}
	}

	return results
}

func ratioCounts(ratioSplits: [String: [Post]]) -> [String] {
	var results = [String]()
	let sortedKeys = ratioSplits.keys.sort { (firstRatio, secondRatio) -> Bool in
		let firstRatioNumber = firstRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		let secondRatioNumber = secondRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		return Int(firstRatioNumber) < Int(secondRatioNumber)
	}

	for key in sortedKeys {
		results.append("\(key): \(ratioSplits[key]!.count)")
	}

	return results
}

func narrowestRatio(ratioSplits: [String: [Post]]) -> String {
	let sortedKeys = ratioSplits.keys.sort { (firstRatio, secondRatio) -> Bool in
		let firstRatioNumber = firstRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		let secondRatioNumber = secondRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		return Int(firstRatioNumber) < Int(secondRatioNumber)
	}

	return sortedKeys.first!	
}

func narrowestFilms(ratioSplits: [String: [Post]]) -> [String] {
	let sortedKeys = ratioSplits.keys.sort { (firstRatio, secondRatio) -> Bool in
		let firstRatioNumber = firstRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		let secondRatioNumber = secondRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		return Int(firstRatioNumber) < Int(secondRatioNumber)
	}

	return ratioSplits[sortedKeys.first!]!.map { $0.title }
}

func widestRatio(ratioSplits: [String: [Post]]) -> String {
	let sortedKeys = ratioSplits.keys.sort { (firstRatio, secondRatio) -> Bool in
		let firstRatioNumber = firstRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		let secondRatioNumber = secondRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		return Int(firstRatioNumber) < Int(secondRatioNumber)
	}

	return sortedKeys.last!
}

func widestFilms(ratioSplits: [String: [Post]]) -> [String] {
	let sortedKeys = ratioSplits.keys.sort { (firstRatio, secondRatio) -> Bool in
		let firstRatioNumber = firstRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		let secondRatioNumber = secondRatio.stringByReplacingOccurrencesOfString(".", withString: "").stringByReplacingOccurrencesOfString(":1", withString: "")
		return Int(firstRatioNumber) < Int(secondRatioNumber)
	}

	return ratioSplits[sortedKeys.last!]!.map { $0.title }
}

func calculateTotalWordsWritten(posts: [Post]) -> String {
	var totalWords = 0
	for post in posts {
		totalWords += post.words
	}

	return "\(totalWords)"
}

func calculateAveratePostLength(posts: [Post]) -> String {
	var totalWords = 0
	var averageWords = 0
	for post in posts {
		totalWords += post.words
	}
	averageWords = totalWords / posts.count

	return "\(averageWords)"
}

func longestWordCount(posts: [Post]) -> String {
	let sortedPosts = posts.sort { $0.words > $1.words}

	return "\(sortedPosts.first!.words) words about \(sortedPosts.first!.title)"
}

func shortestWordCount(posts: [Post]) -> String {
	let sortedPosts = posts.sort { $0.words < $1.words}

	return "\(sortedPosts.first!.words) words about \(sortedPosts.first!.title)"
}

func mostByWeekOfYear(posts: [Post]) -> String {
	var results = [String: [Post]]()

	for post in posts {
		let formatter  = NSDateFormatter()
	    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
	    let date = formatter.dateFromString(post.date)!
	    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
	    let components = calendar.components(.WeekOfYear, fromDate: date)
	    let weekOfYear = "\(components.weekOfYear)"

		if results[weekOfYear] == nil {
			results[weekOfYear] = [Post]()
		}

		results[weekOfYear]?.append(post)
	}

	var most = 0
	for (_, value) in results {
		if value.count > most {
			most = value.count
		}
	}

	return "\(most)"
}

func sortByDaysOfWeek(posts: [Post]) -> [String] {
	var results = [String: [Post]]()

	for post in posts {
		let formatter  = NSDateFormatter()
	    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
	    let date = formatter.dateFromString(post.date)!
	    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
	    let components = calendar.components(.Weekday, fromDate: date)
	    let weekDay = components.weekday

	    var day = ""
	    switch weekDay {
            case 1:
                day = "Sunday"
            case 2:
                day = "Monday"
            case 3:
                day = "Tuesday"
            case 4:
                day = "Wednesday"
            case 5:
                day = "Thursday"
            case 6:
                day = "Friday"
            case 7:
                day = "Saturday"
            default:
                day = "Day"
            }

		if results[day] == nil {
			results[day] = [Post]()
		}

		results[day]?.append(post)
	}

	return results.map { (key, value) in "\(key) - \(value.count)" }
}


// Body

print("What year would you like to generate the stats for:")
let response = readLine(stripNewline: true)
guard let year = response else { 
	print("Exiting because of bad input.")
	fatalError()
}

print("Generating stats for \(year)\n")

let posts = generatePostListForYear(year)
let filmCount = posts.map { $0.films }.reduce(0, combine: +)
let averageRating: Double = round(Double(posts.map { $0.rating}.flatten().reduce(0, combine: +)) / Double(filmCount))
let ratingSplits = generateRatingSplits(posts)
let countrySplits = generateCountrySplits(posts)
let rankedCountries = rankedCategorySplits(countrySplits)
let languageSplits = generateLanguageSplits(posts)
let rankedLanguages = rankedCategorySplits(languageSplits)
let yearSplits = generateYearSplits(posts)
let oldestYear = calculateOldestYear(yearSplits)
let newestYear = calculateNewestYear(yearSplits)
let ratioSplits = generateRatioSplits(posts)

print("\nFor \(year), you wrote \(posts.count) entries about \(filmCount) films")
print("The average rating was a \(Int(averageRating))")
print("The most common rating was a \(mostCommonRating(ratingSplits)), which was given to \(ratingSplits.sort { $0.count > $1.count }[0].count) films")
print("The lowest rated films were \(lowestRatedFilms(ratingSplits).joinWithSeparator(", ")) with a rating of \(lowestRating(ratingSplits))")
print("You watched films from \(countrySplits.keys.count) countries")
print("The country counts were \(rankedCountries)")
print("You watched films in \(languageSplits.keys.count) languages")
print("The most common languages were \(rankedLanguages)")
print("The oldest films you watched were \(yearSplits[oldestYear].map { $0.map { $0.title } }!) from \(oldestYear)")
print("The newest films you watched were \(yearSplits[newestYear].map { $0.map { $0.title } }!) from \(newestYear)")
print("The decade counts were \(decadeCounts(yearSplits))")
print("The narrowest films were \(narrowestFilms(ratioSplits)), with an aspect ratio of \(narrowestRatio(ratioSplits))")
print("The widest films were \(widestFilms(ratioSplits)), with an aspect ratio of \(widestRatio(ratioSplits))")
print("The ratio counts were \(ratioCounts(ratioSplits))")
print("You wrote \(calculateTotalWordsWritten(posts)) words this year, for an average length of \(calculateAveratePostLength(posts)) words.")
print("My longest entry was \(longestWordCount(posts)). My shortest entry was \(shortestWordCount(posts)).")
print("The most you posted in one week was \(mostByWeekOfYear(posts))")
print("The days you posted were \(sortByDaysOfWeek(posts))")
