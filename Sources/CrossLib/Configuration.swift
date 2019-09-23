import Foundation
import TOMLDecoder

public struct Configuration: Codable {
    var target: String
    var build: Build

    public struct Build: Codable {
        var extraCxxFlags: [String] = []
        var linkerScript: String?
    }
}

extension Configuration {
    public static func load(_ url: URL) throws -> Configuration {
        let decoder = TOMLDecoder()
        decoder.keyDecodingStrategy = TOMLDecoder.KeyDecodingStrategy.custom { (path) -> CodingKey in
            CodingKeyImp(stringValue: path.last!.stringValue.pascalCasify())!
        }
        return try decoder.decode(Configuration.self, from: Data(contentsOf: url))
    }
}

private enum CodingKeyImp: CodingKey {
    case string(String)
    case integer(Int)

    var stringValue: String {
        switch self {
        case let .string(stringValue):
            return stringValue
        case let .integer(integerValue):
            return String(integerValue)
        }
    }

    init?(stringValue: String) {
        self = .string(stringValue)
    }

    var intValue: Int? {
        switch self {
        case .string:
            return nil
        case let .integer(integerValue):
            return integerValue
        }
    }

    init?(intValue: Int) {
        self = .integer(intValue)
    }
}

private extension String {
    func pascalCasify(_ separator: Character = "-") -> String {
        guard !isEmpty else { return self }

        // Find the first non-underscore character
        guard let firstNonUnderscore = self.firstIndex(where: { $0 != separator }) else {
            // Reached the end without finding an _
            return self
        }

        // Find the last non-underscore character
        var lastNonUnderscore = index(before: endIndex)
        while lastNonUnderscore > firstNonUnderscore, self[lastNonUnderscore] == separator {
            formIndex(before: &lastNonUnderscore)
        }

        let keyRange = firstNonUnderscore ... lastNonUnderscore
        let leadingUnderscoreRange = startIndex ..< firstNonUnderscore
        let trailingUnderscoreRange = index(after: lastNonUnderscore) ..< endIndex

        let components = self[keyRange].split(separator: separator)
        let joinedString: String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(self[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result: String
        if leadingUnderscoreRange.isEmpty, trailingUnderscoreRange.isEmpty {
            result = joinedString
        } else if !leadingUnderscoreRange.isEmpty, !trailingUnderscoreRange.isEmpty {
            // Both leading and trailing underscores
            result = String(self[leadingUnderscoreRange]) + joinedString + String(self[trailingUnderscoreRange])
        } else if !leadingUnderscoreRange.isEmpty {
            // Just leading
            result = String(self[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(self[trailingUnderscoreRange])
        }
        return result
    }
}
