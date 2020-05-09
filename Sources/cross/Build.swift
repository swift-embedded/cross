import CrossLib
import Foundation
import TOMLDecoder
import ArgumentParser

struct Build: ParsableCommand {
    
    @Argument(help: "name of the command to execute followed by any cargs to do command with")
    var args: [String]
    
    @Option(name: .shortAndLong, default: "Cross.toml", help: "default is Cross.toml")
    var crossFile: String
    
    func run() throws {
        // load the cross file
        let configuration = try Configuration.load(URL(fileURLWithPath: crossFile))
        
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
    }

}
