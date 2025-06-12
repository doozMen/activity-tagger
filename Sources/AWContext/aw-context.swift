import ArgumentParser

@main
struct AWContext: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aw-context",
        abstract: "Add context annotations to ActivityWatch data",
        version: "1.0.0",
        subcommands: [Add.self, Query.self, Search.self, Summary.self, Enrich.self]
    )
}
