#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <semaphore.h>

#define SHM_KEY 9876
#define SHM_SIZE 4000

typedef struct {
    sem_t read_sem;
    sem_t write_sem;
    void* addr;
    char mount_path[1024];
    char events[1024];
} memory_segment;

int main() {
    int shm_id = shmget(SHM_KEY, SHM_SIZE, IPC_CREAT | 0666);
    if (shm_id == -1) {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    char* memory = (char*)shmat(shm_id, NULL, 0);
    if (memory == (char*)-1) {
        perror("shmat");
        exit(EXIT_FAILURE);
    }


    const char* message = "Hello from C!";
    strncpy(memory, message, sizeof(memory));

    printf("Written to shared memory: %s\n", memory);

    while (1) {
        printf("Written to shared memory: %s\n", memory);

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
