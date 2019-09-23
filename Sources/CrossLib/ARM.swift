import Basic
import Build
import Workspace

public func createArmDestination(arch: Triple.Arch) throws -> Destination {
    switch arch {
    case .thumbv7m:
        return try _createArmDestination(llvmTriple: "thumbv7m-unknown-none-eabi",
                                         clangFlags: ["-mthumb", "-mcpu=cortex-m4", "-march=armv7em"],
                                         gccFlags: ["-march=armv7e-m"])
    case .thumbv7em:
        return try _createArmDestination(llvmTriple: "thumbv7em-unknown-none-eabi",
                                         clangFlags: ["-mthumb", "-mcpu=cortex-m3", "-march=armv7m"],
                                         gccFlags: ["-march=armv7-m"])
    default:
        throw Error.unsupported(message: "Architecture \(arch) is not supported.")
    }
}

private func _createArmDestination(llvmTriple: String,
                                   clangFlags: [String],
                                   gccFlags: [String]) throws -> Destination {
    let armToolchain = try ArmNoneEabiToolchain.find()
    let headerFlags = try armToolchain.headerSearchPaths(flags: gccFlags).map { "-I\($0)" }
    let libraryFlags = try armToolchain.librarySearchPaths(flags: gccFlags).map { "-L\($0)" }
    let defaultLibraries = [
        "swiftCore", "swiftStdlibStubsBaremetal",
        "stdc++_nano", "c", "g", "m", "gcc",
    ]

    let target = try Triple(llvmTriple)
    let sdk = try armToolchain.sysroot()
    let toolchainBinDir = try AbsolutePath(shell(cmd: "dirname $(which swift)"))
    let extraCcFlags = [
        "-nostdinc",
        "-target", llvmTriple,
    ] + headerFlags + clangFlags
    let extraSwiftCFlags = [
        "-Xcc", "-ffunction-sections",
        "-Xcc", "-fdata-sections",
        "-Xcc", "-mthumb",
        "-Xlinker", "--gc-sections",
        "-Xfrontend", "-metadata-sections",
        "-Xfrontend", "-function-sections",
        "-Xfrontend", "-data-sections",
        "-static-stdlib",
        "-target", llvmTriple,
        "-use-ld=\(try armToolchain.findProgram("ld"))",
        "-Xcc", "-D_BAREMETAL",
    ] + libraryFlags
        + defaultLibraries.map { "-l\($0)" }

    return Destination(target: target,
                       sdk: sdk,
                       binDir: toolchainBinDir,
                       extraCCFlags: extraCcFlags,
                       extraSwiftCFlags: extraSwiftCFlags,
                       extraCPPFlags: extraCcFlags)
}

public class ArmNoneEabiToolchain {
    public var gccExecutable: String

    public init(gccExecutable: String) {
        self.gccExecutable = gccExecutable
    }

    public static func find() throws -> ArmNoneEabiToolchain {
        if let executable = try? shell(cmd: "xcrun -f arm-none-eabi-gcc") {
            return ArmNoneEabiToolchain(gccExecutable: executable.trimmingCharacters(in: .whitespacesAndNewlines))
        } else if let executable = try? shell(cmd: "which arm-none-eabi-gcc") {
            return ArmNoneEabiToolchain(gccExecutable: executable.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            throw Error.dependencyNotFound(message: "Could not locate arm-none-eabi-gcc.")
        }
    }

    public func findProgram(_ name: String) throws -> AbsolutePath {
        let path = try shell(cmd: "\(gccExecutable) -print-prog-name=\(name)")
        return AbsolutePath(path)
    }

    public func headerSearchPaths(flags: [String]) throws -> [String] {
        let flagsStr = flags.joined(separator: " ")
        var cmd = "echo | \(gccExecutable) -xc++ \(flagsStr) -E -Wp,-v - 2>&1 1>/dev/null "
        cmd += "| grep \'^ \' | sed \'s/^ //g\' | paste -sd\\; -"
        return try shell(cmd: cmd).split(separator: ";").map { String($0) }
    }

    public func sysroot() throws -> AbsolutePath {
        let path = try shell(cmd: "\(gccExecutable) -print-sysroot").trimmingCharacters(in: .whitespacesAndNewlines)
        return AbsolutePath(path)
    }

    public func librarySearchPaths(flags: [String]) throws -> [String] {
        let output = try shell(cmd: "\(gccExecutable) \(flags.joined(separator: " ")) -print-search-dirs")
        for line in output.split(separator: "\n") {
            if line.starts(with: "libraries") {
                let list = line.replacingOccurrences(of: "libraries: =", with: "")
                return list.split(separator: ":").map { String($0) }
            }
        }
        throw Error.subprocessCommunicationFailure(message: "Failed to parse arm-none-eabi-gcc output.")
    }
}

private func shell(cmd: String) throws -> String {
    let process = Process(args: "/usr/bin/env", "sh", "-c", cmd)
    try process.launch()
    let result = try process.waitUntilExit()
    if case let .terminated(code) = result.exitStatus, code != 0 {
        throw Error.subprocessFailed(exitStatus: Int(code),
                                     stderrOutput: (try? result.utf8stderrOutput()) ?? "")
    }
    return try result.utf8Output().trimmingCharacters(in: .whitespacesAndNewlines)
}
