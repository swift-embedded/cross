import CrossLib
import Foundation
import TOMLDecoder

func parsePrefixOptions(args: [String], options: [String: String] = [:])
    -> (args: [String], options: [String: String]) {
    if args.count >= 2, args[0].starts(with: "--") {
        let (key, value) = (String(args[0].dropFirst(2)), args[1])
        return parsePrefixOptions(
            args: Array(args.dropFirst(2)),
            options: options.merging([key: value], uniquingKeysWith: { $1 })
        )
    } else {
        return (args: args, options: options)
    }
}
