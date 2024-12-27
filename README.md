# Distributed-File-System
A Distributed File System made in Swift, C, and gRPC with eventual consistency model. The main rule of this system is that the file with the latest modification time wins. 
# Table of Contents

1. [High-Level Architecture ](#High-Level-Architecture)  
2. [About](#about)  
   - [INotifyService](#inotifyservice)  
   - [Client](#client)  
   - [Server](#server)  
   - [FSService](#fsservice)  
3. [Demo](#demo)  
4. [How to Run](#how-to-run)
5. [Notes](#notes)
## High-Level Architecture  
![DFSLatest](https://github.com/user-attachments/assets/ddec6aff-3c10-4c09-890a-c8fbf35cbd70)

## About
The project consist of different services which are explained below
- INotifyService
- Client
- Server
- FSService

### INotifyService
The INotifyService maps a shared memory region that it shares with the client process. This shared memory is used to exchange information about file changes. The service also monitors a specific directory (mount path) that the user wants to track. It does this by using the inotify API, which watches for file system events such as adding, modifying, or deleting files.

Whenever a file change occurs, the INotifyService writes the details of the event (e.g., file name, type of change) into the shared memory region. After updating the shared memory, the service signals a semaphore to let the Swift client know that a new event has occurred. Once notified, the client reads the event details from the shared memory and takes the appropriate action, such as:

- Fetching the updated file,
- Storing new data, or
- Deleting the file if it was removed.

This process repeats continuously for as long as the system is running, by utilizing the [reader-writer semaphore pattern](https://en.wikipedia.org/wiki/Readers%E2%80%93writers_problem) inspired during my reading of [Operating Systems: Three Easy Pieces](https://pages.cs.wisc.edu/~remzi/OSTEP/) book.

### Client
The Client can work in two ways:
- Single Operation:

The client does one task, such as: Fetching, storing, or deleting a file. After completing the task, it stops.

- Continuous Monitoring:
  
The client keeps running until the user stops the process. Use the --mount command to start this mode. The mount command connects to the shared memory created by the INotifyService and keeps checking for updates in the shared memory. When it finds an update, it reads the event and acts, like fetching, storing, or deleting files. This mode is useful for real-time file monitoring and syncing. Additionally, in this mode, the client will also listen to the FSService.

### Server
The server the client connects to. It serves as the source of truth, and all of the operations will go to this server.

### FSService
This service is a real-time socket server that updates all connected clients when server has an updated item. When the client runs the mount mode, it will connect to the socket service and wait for any update on another thread. When the server recieves an update (store or delete) it will send a POST request to this server in which it will then notify all connected clients that it's time to fetch from the server.

## Demo

## How to Run
Run the executables in the following order: FSService > Server > INotifyService > Client. Note, you need to run docker as well. 

### Docker
```
docker run --privileged -it --rm -v "$(pwd):/app" my-project-env
```

### [Optional] tmux installation
```
apt-get update && apt-get install -y sudo
sudo apt install tmux
```

### FSService
```
cd FSService/Sources
swift run FSService
```

### Server
```
cd Server/Sources
swift run DFSServer
```

### InotifyService
```
cd InotifyService
make
./main -m files -s 1357 -r read -w write
```

### Client
1. Single Operation
```
cd Client/Sources
swift run DFSClient [command] therepublic.txt // command is one of [fetch, store, delete]
```
2. Continuous Monitoring
```
cd Client/Sources
swift run DFSClient mount [path] // by default, path is /files
```

## Notes
- When testing the application with the mount command, use VS Code to write or delete files. I initially tried using Xcode, but it appears that Xcode performs multiple steps behind the scenes when writing to a file. This results in inaccurate or unexpected inotify events. I assume vim or nano to be accurate as well, but I didn't test the application using them yet.
