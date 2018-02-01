#!/usr/bin/swift

import Foundation

// Constants
let sourceDirectory = "/Users/arik/Development/danieltiger.github.io/source/_posts"
let fileManager = FileManager.default
let year = String(Calendar.current.component(.year, from: Date()))

// Library
struct Post {
	var published = true
	var title = ""
	var date = ""
	var rating = ""
	var runningTime = ""
	var seenBefore = ""
	var countries = [String]()
	var languages = [String]()
	var years = [String]()
	var decades = [String]()
	var ratios = [String]()
	var length = ""
	var week = ""
	var day = ""

	var content = [String]() {
		didSet {
			updateStatus()
		}
	}
}

extension Post {

	mutating func updateStatus() {
		for line in self.content {
			if line.hasPrefix("> ") { break }

			switch line {
			case _ where line.hasPrefix("date: "):
				date = extractDate(for: line)
			case _ where line.hasPrefix("published: "):
		    	published = false
			case _ where line.hasPrefix("title: "):
				title = extractTitle(for: line)
			case _ where line.hasPrefix("rating: "):
				rating = extractContent(for: line)
			case _ where line.hasPrefix("time: "):
				runningTime = extractContent(for: line)
			case _ where line.hasPrefix("seen: "):
				seenBefore = extractContent(for: line)
			case _ where line.hasPrefix("categories: "):
				updateCategories(for: line);
			case _ where line.hasPrefix("length: "):
				length = extractContent(for: line)
			case _ where line.hasPrefix("week: "):
				week = extractContent(for: line)
			case _ where line.hasPrefix("day: "):
				day = extractContent(for: line)
			default: ()
			}
		}
	}

	func extractDate(for line: String) -> String {
		let firstSpace = line.index(of: " ") ?? line.endIndex
		let firstDash = line.index(of: "-") ?? line.endIndex
		return String(line[firstSpace..<firstDash]).trimmingCharacters(in: .whitespaces)
	}

	func extractTitle(for line: String) -> String {
		return extractContent(for: line).replacingOccurrences(of: "\"", with: "")
	}

	func extractContent(for line: String) -> String {
		let firstSpace = line.index(of: " ") ?? line.endIndex
		return String(line[firstSpace..<line.endIndex]).trimmingCharacters(in: .whitespaces)
	}

	// categories: ["Italy", "Germany", "1928", "1.33:1", German, Italian]
	mutating func updateCategories(for line: String) {
		let content = extractContent(for: line)
		guard content.isEmpty == false else { return }

		var hasFoundYear = false
		let categories = content.components(separatedBy: ", ")
		for category in categories {
			if category.index(of: "\"") != nil {
				hasFoundYear = true
			}

			let strippedCategory = category.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

			if hasFoundYear == false {
				countries.append(strippedCategory)
			} else if Int(strippedCategory) != nil {
				years.append(strippedCategory)
				decades.append("\(String(strippedCategory.dropLast()))0")
				decades = Array(Set(decades))
			} else if strippedCategory.contains(":") {
				ratios.append(strippedCategory)
			} else if hasFoundYear == true {
				languages.append(strippedCategory)
			}
		}
	}
	
}

extension Post {
	
	func csv() -> [String] {
		var output = [String]()

		output.append(constructEntry(title: title, rating: rating, runningTime: runningTime, seenBefore: seenBefore, country: countries.first, language: languages.first, year: years.first, decade: decades.first, ratio: ratios.first, length: length, week: week, day: day))

		for (index, country) in countries.enumerated() {
			guard index > 0 else { continue }
			output.append(constructEntry(title: title, country: country))
		}

		for (index, language) in languages.enumerated() {
			guard index > 0 else { continue }
			output.append(constructEntry(title: title, language: language))
		}

		for (index, year) in years.enumerated() {
			guard index > 0 else { continue }
			output.append(constructEntry(title: title, year: year))
		}

		for (index, decade) in decades.enumerated() {
			guard index > 0 else { continue }
			output.append(constructEntry(title: title, decade: decade))
		}

		for (index, ratio) in ratios.enumerated() {
			guard index > 0 else { continue }
			output.append(constructEntry(title: title, ratio: ratio))
		}

		return output
	}

	func constructEntry(title: String = "", rating: String = "", runningTime: String = "", seenBefore: String = "", country: String? = "", language: String? = "", year: String? = "", decade: String? = "", ratio: String? = "", length: String = "", week: String = "", day: String = "") -> String {
		return "\(title),\(rating),\(runningTime),\(seenBefore),\(country ?? ""),\(language ?? ""),\(year ?? ""),\(decade ?? ""),\(ratio ?? ""),\(length),\(week),\(day)"
	}

}

func posts() throws -> [Post] {
	let filenames = try fileManager.contentsOfDirectory(atPath: sourceDirectory)

	var posts = [Post]()
	for filename in filenames {
		var post = Post()
		post.content = try String(contentsOf: URL(fileURLWithPath: "\(sourceDirectory)/\(filename)")).components(separatedBy: "\n")

		if post.date == year && post.published == true {
			posts.append(post)
		}
	}

	return posts
}

func generateCSV(for posts: [Post]) -> [String] {
	var output = [String]()

	output.append("title,rating,running time,seen before?,country,language,year,decade,aspect ratio,entry length,week,day")

	for post in posts {
		output.append(contentsOf: post.csv())
	}

	return output
}

// Main

do {
	let postList = try posts()
	let csv = generateCSV(for: postList)
	print(csv.joined(separator: "\n"))
} catch {
	fatalError()
}