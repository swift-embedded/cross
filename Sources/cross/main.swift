import CrossLib
import Foundation
import TOMLDecoder

let (args, options) = parsePrefixOptions(args: Array(CommandLine.arguments.dropFirst()))
var crossFileName = options["cross-file"] ?? "Cross.toml"

do {
    // load the cross file
    let configuration = try Configuration.load(URL(fileURLWithPath: crossFileName))

    // prepare the target
    let target = try createTarget(configuration: configuration)

    // generate the destination info
    let buildDirectory = FileManager.default.currentDirectoryPath.appending("/.build")

    let destination = try target.createDestination(buildDirectory: buildDirectory)

    if !FileManager.default.fileExists(atPath: buildDirectory) {
        try FileManager.default.createDirectory(atPath: buildDirectory, withIntermediateDirectories: false)
    }
    let destinationPath = buildDirectory + "/destination.json"

    // write the destination info to a file
    try destination.toJSON().toString(prettyPrint: true)
        .write(toFile: destinationPath, atomically: true, encoding: .utf8)

    let destinationArgs = ["--destination", destinationPath]

    // perform specified command
    if args.count > 0, args[0] == "build" {
        let swift = destination.binDir.appending(component: "swift").pathString
        let cargs = [strdup(swift)] + args.map { strdup($0) } + destinationArgs.map { strdup($0) } + [nil]
        execv(swift, cargs)
    }
} catch {
    fatalError("\(error)")
}
