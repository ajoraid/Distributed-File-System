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
#include <sys/inotify.h>

#define EVENT_SIZE (sizeof(struct inotify_event))
#define EVENT_BUFFER_LEN 256
#define SHM_KEY 1357
#define SHM_SIZE 1024

typedef struct
{
    char event[256];
} memory_segment;

void cleanup()
{
    printf("Program is exiting, cleaning up\n");
    sem_unlink("/read_sem");
    sem_unlink("/write_sem");
}

void sigint_handler(int signum)
{
    printf("\nSIGINT\n");
    cleanup();
    exit(0);
}

int main()
{
    if (signal(SIGINT, sigint_handler) == SIG_ERR)
    {
        perror("Unable to catch SIGINT");
        return EXIT_FAILURE;
    }
    int shm_id = shmget(SHM_KEY, SHM_SIZE, IPC_CREAT | 0666);
    if (shm_id == -1)
    {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    memory_segment *memory = (memory_segment *)shmat(shm_id, NULL, 0);
    if (memory == (memory_segment *)-1)
    {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    sem_t *rsem = sem_open("/read_sem", O_CREAT, S_IRUSR | S_IWUSR, 0);
    sem_t *wsem = sem_open("/write_sem", O_CREAT, S_IRUSR | S_IWUSR, 1);

    if (rsem == SEM_FAILED || wsem == SEM_FAILED)
    {
        perror("sem_open");
        exit(EXIT_FAILURE);
    }

    const char *event = "THIS WILL BE inotify EVENT!";
    strncpy(memory->event, event, sizeof(memory->event));

    int fd;
    int wd;
    char buffer[EVENT_BUFFER_LEN];

    fd = inotify_init();
    if (fd == -1)
    {
        perror("inotify_init");
        exit(1);
    }

    wd = inotify_add_watch(fd, "../Client/Sources/files", IN_MODIFY | IN_CREATE | IN_DELETE | IN_ONLYDIR);
    if (wd == -1)
    {
        perror("inotify_add_watch");
        exit(1);
    }

    while (1)
    {
        sem_wait(wsem);
        memset(memory->event, 0, sizeof(memory->event));
        char event_buffer[EVENT_BUFFER_LEN];
        int length = read(fd, buffer, EVENT_BUFFER_LEN);
        if (length < 0)
        {
            perror("read");
            exit(1);
        }
        int i = 0;
        event_buffer[0] = '\0';
        while (i < length)
        {
            struct inotify_event *event = (struct inotify_event *)&buffer[i];
            if (event->len)
            {
                switch (event->mask)
                {
                case IN_CREATE:
                    printf("File %s created.\n", event->name);
                    snprintf(event_buffer, sizeof(event_buffer), "%s|%s", event->name, "create");
                    break;
                case IN_DELETE:
                    printf("File %s deleted.\n", event->name);
                    snprintf(event_buffer, sizeof(event_buffer), "%s|%s", event->name, "delete");
                    break;
                case IN_MODIFY:
                    printf("File %s modified.\n", event->name);
                    snprintf(event_buffer, sizeof(event_buffer), "%s|%s", event->name, "modify");
                    break;
                default:
                    break;
                }
            }
            int used = EVENT_SIZE + event->len;
            i += (used / sizeof(char));
        }
        strncpy(memory->event, event_buffer, sizeof(memory->event));
        printf("Event: %s\n", memory->event);
        sem_post(rsem);
    }

    if (shmdt(memory) == -1)
    {
        perror("shmdt");
    }

    if (shmctl(shm_id, IPC_RMID, NULL) == -1)
    {
        perror("shmctl");
    }

    sem_unlink("/read_sem");
    sem_unlink("/write_sem");

    inotify_rm_watch(fd, wd);
    close(fd);

    return EXIT_SUCCESS;
}
