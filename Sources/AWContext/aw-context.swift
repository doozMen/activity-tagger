import ArgumentParser
import AWContextLib

@main
struct AWContext: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aw-context",
        abstract: "Add context annotations to ActivityWatch data",
        version: AWContextVersion.fullVersion,
        subcommands: [AWContextLib.Add.self, AWContextLib.Query.self, AWContextLib.Search.self, AWContextLib.Summary.self, AWContextLib.Enrich.self]
    )
}
