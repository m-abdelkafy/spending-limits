import Foundation

enum CSVParser {
    static func parse(url: URL) throws -> [[String]] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return parse(text: text)
    }

    static func parse(text: String) -> [[String]] {
        var rows: [[String]] = []
        var current: [String] = []
        var field = ""
        var inQuotes = false
        var i = text.startIndex

        while i < text.endIndex {
            let ch = text[i]
            if inQuotes {
                if ch == "\"" {
                    let next = text.index(after: i)
                    if next < text.endIndex && text[next] == "\"" {
                        field.append("\"")
                        i = text.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    current.append(field)
                    field = ""
                } else if ch == "\n" || ch == "\r\n" {
                    current.append(field)
                    field = ""
                    if !(current.count == 1 && current[0].isEmpty) {
                        rows.append(current)
                    }
                    current = []
                } else if ch == "\r" {
                    // ignore lone CR; the LF that typically follows will commit the row
                } else {
                    field.append(ch)
                }
            }
            i = text.index(after: i)
        }

        // Flush the last field/row if non-empty
        current.append(field)
        if !(current.count == 1 && current[0].isEmpty) {
            rows.append(current)
        }
        return rows
    }
}
