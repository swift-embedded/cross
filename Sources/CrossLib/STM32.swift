import Build
import Foundation
import Workspace

public class STM32Target: Target {
    public enum Microcontroller: String, CaseIterable {
        case STM32F439ZI
    }

    public let mcu: Microcontroller
    private let configuration: Configuration
    private let fileManager = FileManager.default

    public required init?(configuration: Configuration) throws {
        guard let mcu = Microcontroller(rawValue: configuration.target) else {
            return nil
        }
        self.mcu = mcu
        self.configuration = configuration
    }

    public func writeLinkerScript(at path: String) throws {
        let linkerScript = linkerScriptTemplate
        try linkerScript.write(toFile: path, atomically: true, encoding: .utf8)
    }

    public func createDestination(buildDirectory: String) throws -> Destination {
        // create build directory (if needed)
        if !fileManager.fileExists(atPath: buildDirectory) {
            try fileManager.createDirectory(atPath: buildDirectory, withIntermediateDirectories: true)
        }

        // write down the linker script
        let linkerScriptPath = buildDirectory + "/linker-script.ld"
        try writeLinkerScript(at: linkerScriptPath)

        // prepare extra flags
        let arch: Triple.Arch
        var cxxFlags = [String]()
        var swiftcFlags = ["-Xlinker", "-T", "-Xlinker", linkerScriptPath]

        switch mcu {
        case .STM32F439ZI:
            let cFlags = ["-DSTM32F439xx",
                          "-D_POSIX_THREADS", "-D_POSIX_READER_WRITER_LOCKS",
                          "-D_UNIX98_THREAD_MUTEX_ATTRIBUTES", "-D_WANT_REENT_GLOBAL_STDIO_STREAMS"]
            cxxFlags += cFlags
            swiftcFlags += cFlags.flatMap { ["-Xcc", $0] }
            arch = .thumbv7m
        }

        // create the final destination for this device
        let destination = try createArmDestination(arch: arch)
        return destination.updated(extraCCFlags: destination.extraCCFlags + cxxFlags,
                                   extraSwiftCFlags: destination.extraSwiftCFlags + swiftcFlags,
                                   extraCPPFlags: destination.extraCPPFlags + cxxFlags)
    }
}
