# Distributed-File-System
Playing around with Swift and gRPC for now to implement a basic distributed file system with eventual consistency. The file with the latest modification time wins (should be the one present). I'm also planning to implement an inotify service in C that will write notifications occurring in a mounted path to shared memory, which the Swift client can then read from. Additionally, the Swift client will send the mounted path entered by the user through a POSIX message queue (one-time send). Below is a really high-level diagram of what I currently have in my head.

# Diagram 
![DFS](https://github.com/user-attachments/assets/af24acf5-5ad9-4447-aaef-808072dd48a6)

# How I feel about Swift and gRPC 
I implemented a "smaller" part of this project in C++ previously, and I really loved working with C++ and gRPC. However, I'm unsure how I feel about working with Swift and gRPC. I'm still early in the project, but I hope there are better ways, and I’m just doing it wrong.
