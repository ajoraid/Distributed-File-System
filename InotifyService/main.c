#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <semaphore.h>

#define SHM_KEY 1234
#define SHM_SIZE sizeof(memory_segment)

typedef struct {
    char events[256];
    char wsem[256];
} memory_segment;

int main() {
    int shm_id = shmget(SHM_KEY, SHM_SIZE, IPC_CREAT | 0666);
    if (shm_id == -1) {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    memory_segment* memory = (memory_segment*)shmat(shm_id, NULL, 0);
    if (memory == (memory_segment*)-1) {
        perror("shmat");
        exit(EXIT_FAILURE);
    }


    const char* message = "Hello from C!";
    const char* message2 = "Hello from sem!";
    strncpy(memory->events, message, sizeof(memory->events));
    strncpy(memory->wsem, message2, sizeof(memory->wsem));


    while (1) {
        printf("Written to shared memory: %s\n", memory->events);
        printf("Written to shared memory: %s\n", memory->wsem);

        sleep(20);
    }

    if (shmdt(memory) == -1) {
        perror("shmdt");
    }

    if (shmctl(shm_id, IPC_RMID, NULL) == -1) {
        perror("shmctl");
    }

    return 0;
}
