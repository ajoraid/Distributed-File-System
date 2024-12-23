#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <semaphore.h>
#include <fcntl.h>
#include <signal.h>

#define SHM_KEY 1357
#define SHM_SIZE 1024

typedef struct {
    char event[256];
} memory_segment;

void cleanup() {
    printf("Program is exiting, cleaning up\n");
    sem_unlink("/read_sem");
    sem_unlink("/write_sem");
}

void sigint_handler(int signum) {
    printf("\nSIGINT\n");
    cleanup();
    exit(0);
}

int main() {
    if (signal(SIGINT, sigint_handler) == SIG_ERR) {
        perror("Unable to catch SIGINT");
        return EXIT_FAILURE;
    }
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

    sem_t* rsem = sem_open("/read_sem", O_CREAT, S_IRUSR | S_IWUSR, 0);
    sem_t* wsem = sem_open("/write_sem", O_CREAT, S_IRUSR | S_IWUSR, 1);

    if (rsem == SEM_FAILED || wsem == SEM_FAILED) {
        perror("sem_open");
        exit(EXIT_FAILURE);
    }

    const char* event = "THIS WILL BE inotify EVENT!";
    strncpy(memory->event, event, sizeof(memory->event));

    while (1) {
        sem_wait(wsem);
        printf("Event: %s\n", memory->event);
        sem_post(rsem);
        sleep(5);
        
    }

    if (shmdt(memory) == -1) {
        perror("shmdt");
    }

    if (shmctl(shm_id, IPC_RMID, NULL) == -1) {
        perror("shmctl");
    }

    sem_unlink("/read_sem");
    sem_unlink("/write_sem");

    return EXIT_SUCCESS;
}
