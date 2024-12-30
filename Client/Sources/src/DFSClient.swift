//
//  DFSClient.swift
//  DFSClient
//
//  Created by Adnan Joraid on 2024-12-14.
//

import Foundation
import GRPC
import NIO
import CryptoSwift
import Vapor
class DFSClient: @unchecked Sendable {
    private let key: Int
    private let address: String
    private let mountPath: String
    private let timeout: Int
    private var client: DFSServiceNIOClient?
    private var userID: String
    private let fileManager = FileManager.default
    private var lock = NSLock()
    
    init(key: Int,
         address: String,
         mountPath: String,
         timeout: Int) {
        self.address = address
        self.mountPath = mountPath
        self.timeout = timeout
        self.key = key
        userID = UUID().uuidString
    }
    
    func processCommand(for command: DFSClientCLI.Command, fileName: String) {
        switch command {
        case .fetch:
            fetch(fileName)
        case .store:
            store(fileName)
        case .delete:
            delete(fileName)
        case .mount:
            Task.detached { self.listenToServerUpdateList() }
            setupInotifySharedMemory()
        }
    }
    
    private func inotifyWatcher() {}
    
    private func setupInotifySharedMemory() {
        let SHM_KEY: key_t = key_t(key)
        let SHM_SIZE = 1024

        let shm_id = shmget(SHM_KEY, SHM_SIZE, 0666)
        if shm_id == -1 {
            perror("shmget")
            print("Error code: \(errno)")
            exit(EXIT_FAILURE)
        }

        guard let shmPtr = shmat(shm_id, nil, 0), shmPtr != UnsafeMutableRawPointer(bitPattern: -1) else {
            perror("shmat failed")
            exit(EXIT_FAILURE)
        }

        let sharedMemoryContent = shmPtr.assumingMemoryBound(to: UInt8.self)
        let wsemData = Data(bytes: sharedMemoryContent.advanced(by: 255), count: 255)
        let rsemData = Data(bytes: sharedMemoryContent.advanced(by: 255 * 2), count: 255)

        guard let wsemString = String(data: wsemData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) else { print("can't parse wsemString from shared memory"); exit(1) }
        guard let rsemString = String(data: rsemData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) else { print("can't parse rsemString from shared memory"); exit(1) }
        
        guard let rsem = sem_open(wsemString, 0) else {
            perror("Failed to open read semaphore")
            return
        }

        guard let wsem = sem_open(rsemString, 0) else {
            perror("Failed to open write semaphore")
            return
        }
        
        while true {
            sem_wait(rsem)
            let eventsData = Data(bytes: sharedMemoryContent, count: 255)
            let cleanData = eventsData.prefix { $0 != 0 }
            if let eventsString = String(data: cleanData, encoding: .utf8) {
                let inotifyData = eventsString.split(separator: "|")
                let (filename, event) = (String(inotifyData[0]), String(inotifyData[1]))
                lock.lock()
                switch event {
                case "create":
                    store(filename)
                case "modify":
                    store(filename)
                case "delete":
                    delete(filename)
                default:
                    break
                }
                lock.unlock()
            }
            sem_post(wsem)
        }

        if sem_close(rsem) == -1 {
            perror("Failed to close read semaphore")
        }
        if sem_close(wsem) == -1 {
            perror("Failed to close write semaphore")
        }
    }

    func run() {
        let configuration = ClientConnection(configuration: .default(target: .hostAndPort(address, 27000),
                                                                     eventLoopGroup: MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)))
        client = DFSServiceNIOClient(channel: configuration)
    }
    
    private func listenToServerUpdateList() {
        WebSocket.connect(to: "ws://localhost:8080/socket", on: MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)) { [weak self] ws in
            guard let self else { print("self is nil in listenToServerUpdate"); return }
            ws.onText { ws, str in
                self.lock.lock()
                defer { self.lock.unlock() }
                self.handlePubSubFileEvents()
            }
        }
    }
    
    private func handlePubSubFileEvents() {
        guard let client else {
            print("LOG: Tried calling lock but client is nil")
            return
        }
        var request = EmptyResponse()
        let status = client.pubSubFileEvents(request)
        Task {
            do {
                let res = try await status.response.get()
                let files = res.files
                let path = "./\(self.mountPath)/"
                handleDeletion(res.tombstones)
                for file in files {
                    if !fileManager.fileExists(atPath: path + file.fileName) {
                        if !res.tombstones.contains(where: { $0.fileName == file.fileName }) {
                            fetch(file.fileName)
                        }
                    } else {
                        let currChecksum = getFileCheckSum(file.fileName)
                        let currModTime = getFileModificationAndCreationTime(filePath: path + file.fileName).0
                        if currChecksum == file.fileChecksum { continue }
                        if currModTime > file.mtime {
                            let attribtues = try fileManager.attributesOfItem(atPath: "/\(mountPath)/\(file.fileName)")
                            let fileSize = attribtues[.size] as? Int
                            if fileSize ?? 0 == 0 && currChecksum == file.fileChecksum { continue }
                            store(file.fileName)
                        }
                        else { fetch(file.fileName) }
                    }
                }
            } catch {
                print("Error while waiting for the response: \(error)")
            }
        }
    }
    
    private func handleDeletion(_ stones: [Stones]) {
        let currDirMap = getCurrentFilesAtMountDirectory()
        let path = "./\(self.mountPath)/"
        for deleted in stones {
            if let currentModificationAndCreationTime = currDirMap[deleted.fileName] {
                if !handleServerDeletion(currentModificationAndCreationTime, deleted) {
                    store(deleted.fileName)
                }
            }
        }
    }
    
    private func handleServerDeletion(_ currentModificationAndCreationTime: (UInt64, UInt64), _ stale: Stones) -> Bool {
        let (mtime, ctime) = currentModificationAndCreationTime
        if stale.deletionTime > mtime && stale.deletionTime > ctime {
            do { try fileManager.removeItem(atPath: "./\(self.mountPath)/\(stale.fileName)") }
            catch { print("error deleting at handleserverdeletion: \(error.localizedDescription)") }
            return true
        }
        return false
    }
    
    private func lock(_ filename: String) -> GRPCStatus.Code {
        guard let client else {
            print("LOG: Tried calling lock but client is nil")
            return GRPCStatus.Code.cancelled
        }
        var request = FileRequest()
        request.fileName = filename
        request.userid = userID
        let status = client.lock(request)
        do {
            let _ = try status.response.wait()
            print("Response received")
            return GRPCStatus.Code.ok
        } catch let grpcError as GRPCStatus {
            print("Error while waiting for response: \(grpcError)")
            return grpcError.code
        } catch {
            print("Unexpected error: \(error)")
            return GRPCStatus.Code.unknown
        }
    }
    
    private func store(_ filename: String) {
        guard let client else {
            print("LOG: Tried calling store but client is nil")
            return
        }

        if lock(filename) == .resourceExhausted {
            print("File already locked on server: \(filename). Skipping upload.")
            return
        }
        let path = "./\(mountPath)/\(filename)"
        let (mtime, ctime) = getFileModificationAndCreationTime(filePath: path)
        var request = FileRequest()
        request.fileName = filename
        request.mtime = mtime
        request.ctime = ctime
        request.fileChecksum = getFileCheckSum(filename)
        let chunkSize = 1024
        let fileURL = URL(fileURLWithPath: path)

        do {
            let call = client.store()
            let fileHandle = try FileHandle(forReadingFrom: fileURL)

            while let chunk = try? fileHandle.read(upToCount: chunkSize), !chunk.isEmpty {
                request.fileContent = chunk
                try call.sendMessage(request).wait()
            }

            try call.sendEnd().wait()

            call.response.whenComplete { result in
                switch result {
                case .success(let response):
                    print("Successfully stored file on server: \(response)")
                case .failure(let error):
                    if let grpcError = error as? GRPCStatus, grpcError.code == .alreadyExists {
                        print("Server rejected storage: File already exists.")
                    } else {
                        print("Failure: \(error)")
                    }
                }
            }

            try fileHandle.close()

        } catch {
            if let grpcError = error as? GRPCStatus, grpcError.code == .alreadyExists {
                print("Server rejected storage: File already exists.")
            } else {
                print("Error during file operation: \(error)")
            }
        }
    }

    private func fetch(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling fetch but client is nil")
            return
        }
        let path = "./\(self.mountPath)/\(filename)"
        var request = FileRequest()
        var madeEmpty = false
        let (mtime, ctime) = getFileModificationAndCreationTime(filePath: path)
        request.fileName = filename
        if fileManager.fileExists(atPath: path) {
            request.fileChecksum = getFileCheckSum(filename)
            request.mtime = mtime
            request.ctime = ctime
        }
        let call = client.fetch(request) { [weak self] response in
            guard let self else { print("self is nil in fetch"); return }
            print("Received chunk: \(response.fileContent) bytes")
            
            let fileURL = URL(fileURLWithPath: path)
            
            if !self.fileManager.fileExists(atPath: path) {
                self.fileManager.createFile(atPath: path, contents: nil, attributes: nil)
            }
            
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                if !madeEmpty { fileHandle.truncateFile(atOffset: 0); madeEmpty.toggle() }
                defer { try? fileHandle.close() }
                fileHandle.seekToEndOfFile()
                fileHandle.write(response.fileContent)
            } catch {
                print("Error writing to file: \(error.localizedDescription)")
            }
        }
        do { _ = try call.status.wait() } catch { print(error) }
    }
    
    private func delete(_ filename: String) {
        guard let client = client else {
            print("LOG: Tried calling store but client is nil")
            return
        }
        if lock(filename) == .resourceExhausted {
            print("File already locked on server: \(filename). Skipping upload.")
            return
        }
        var data = FileRequest()
        data.fileName = filename
        let status = client.delete(data)
        do {
            let _ = try status.response.wait()
            print("Response received successfully.")
        } catch {
            print("Error while waiting for the response: \(error)")
        }
    }
    
    private func getFileCheckSum(_ filename: String) -> UInt32 {
        let path = "./\(mountPath)/\(filename)"
        let fileURL = URL(fileURLWithPath: path)
        
        if !fileManager.fileExists(atPath: path) {
            print("File does not exist. Checksum failed")
            return 0
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let checksum = Checksum.crc32(Array(data))
            return checksum
        } catch {
            print(error.localizedDescription)
        }
        return 0
    }
    
    func getFileModificationAndCreationTime(filePath: String) -> (UInt64, UInt64) {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            let modificationTime = attributes[.modificationDate] as? Date
            let creationTime = attributes[.creationDate] as? Date
            return (UInt64(modificationTime?.timeIntervalSince1970 ?? 0), UInt64(creationTime?.timeIntervalSince1970 ?? 0))
        } catch {
            print("Error getting file attributes: \(error)")
        }
        return (0,0)
    }
    
    func getCurrentFilesAtMountDirectory() -> [String: (UInt64, UInt64)] {
        let baseDirPath =  "./\(mountPath)"
        var filesMap = [String: (UInt64, UInt64)]()
        do {
            let files = try fileManager.contentsOfDirectory(atPath: baseDirPath)
            filesMap = files.reduce(into: [:]) { (result, fileName) in
                let filePath = baseDirPath + "/\(fileName)"
                let (mtime, ctime) = getFileModificationAndCreationTime(filePath: filePath)
                result[fileName] = (mtime, ctime)
            }
        } catch { print(error.localizedDescription) }
        return filesMap
    }
}
