//
//  DFSClientCLI.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import ArgumentParser
import Figlet

let usage: String =
    """
    
    
    USAGE: swift run DFSClient [OPTIONS] COMMAND [FILENAME]
    --address: The server address (default to 127.0.0.1)
    --mount-path: The path the client needs to mount to (default to currentDirectory/files)
    --deadline: The request timeout deadline in milliseconds (default to 10000)
    
    COMMAND is one of mount|fetch|store|delete
    FILENAME is filename to fetch, store, or delete
    
    
    """
let usageHelpMessage = ArgumentHelp(stringLiteral: usage)

@main
struct DFSClientCLI: ParsableCommand {
    @Option(help: usageHelpMessage)
    public var address: String = "127.0.0.1"
    
    @Option(help: usageHelpMessage)
    public var mountPath: String = "/files"
    
    @Option(help: usageHelpMessage)
    public var timeout: Int = 10000
    
    @Argument(help: usageHelpMessage)
    public var command: String
    
    @Argument(help: usageHelpMessage)
    public var fileName: String
    
    func run() throws {
        Figlet.say("DFS CLIENT")
        guard let validCommand = Command.fromString(command) else {
            throw ValidationError("Invalid command. Please choose one of mount|fetch|store|delete")
        }
        let client = DFSClient(address: address,
                               mountPath: mountPath,
                               timeout: timeout)
        
        client.run()
        client.processCommand(for: validCommand, fileName: fileName)
    }
}
