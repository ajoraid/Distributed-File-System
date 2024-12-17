//
//  DFSServerCLI.swift
//  DFSServer
//
//  Created by Adnan Joraid on 2024-12-16.
//

import ArgumentParser
import Figlet

let usage: String =
    """

    
    USAGE: swift run DFSServer [OPTIONS] COMMAND [FILENAME]
    --address: The server address (default to 127.0.0.1)
    --mount-path: The path the client needs to mount to (default to currentDirectory/files)
    --deadline: The request timeout deadline in milliseconds (default to 10000)


    """
let usageHelpMessage = ArgumentHelp(stringLiteral: usage)

@main
struct DFSServerCLI: ParsableCommand {
    @Option(help: usageHelpMessage)
    public var address: String = "127.0.0.1"
    
    @Option(help: usageHelpMessage)
    public var mountPath: String = "/files"
    
    @Option(help: usageHelpMessage)
    public var timeout: Int = 10000
    
    func run() throws {
        Figlet.say("DFS SERVER")
        let server = DFSServer(address: address,
                               mountPath: mountPath,
                               timeout: timeout)
        
        try server.run()
    }
}
