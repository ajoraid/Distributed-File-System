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
#include <getopt.h>

#define EVENT_SIZE (sizeof(struct inotify_event))
#define EVENT_BUFFER_LEN 256
#define SHM_SIZE 1024
#define USAGE                                                                                                       \
	"usage:\n"                                                                                                      \
	"  INotifyService [options]\n"                                                                                  \
	"options:\n"                                                                                                    \
	"  -m [mount_path]      Path to folder to be watched\n"                                                         \
    "  -s [shm_key]         The key to be used to open shared memory\n"                                             \
	"  -r [read_semaphore]  The name of read semaphore to be used between Swift client and this service\n"          \
	"  -w [write_semaphore] The name of write semaphore to be used between Swift client and this service\n "        \
	"  -h Display help message\n"

struct option long_options[] = {
    {"mount_path", required_argument, 0, 'm'},
    {"shm_key", required_argument, 0, 's'},
    {"read_semaphore", required_argument, 0, 'r'},
    {"write_semaphore", required_argument, 0, 'w'},
    {"help", no_argument, 0, 'h'},
    {0, 0, 0, 0}};

const char *mount_path = NULL;
const char *shm_key_string = NULL;
char *endPtr;
const char *read_semaphore = NULL;
const char *write_semaphore = NULL;

void usage()
{
	fprintf(stdout, "%s", USAGE);
}

typedef struct
{
    char event[256];
    char resem[256];
    char wrsem[256];
} memory_segment;

void cleanup()
{
    printf("Program is exiting, cleaning up\n");
    sem_unlink(read_semaphore);
    sem_unlink(write_semaphore);
}

void sigint_handler(int signum)
{
    printf("\nSIGINT\n");
    cleanup();
    exit(0);
}

int main(int argc, char *argv[])
{
    int opt;
    int option_index = 0;

    while ((opt = getopt_long(argc, argv, "m:s:r:w:h", long_options, &option_index)) != -1)
    {
        switch (opt)
        {
        case 'm':
            mount_path = optarg;
            break;
        case 's':
            shm_key_string = optarg;
            break;
        case 'r':
            read_semaphore = optarg;
            break;
        case 'w':
            write_semaphore = optarg;
            break;
        case 'h':
            usage();
            exit(0);
        default:
            usage();
            exit(EXIT_FAILURE);
        }
    }

    if (!mount_path || !shm_key_string || !read_semaphore || !write_semaphore)
    {
        fprintf(stderr, "Error: Missing required arguments\n");
        usage();
        exit(EXIT_FAILURE);
    }

    long shm_key = strtol(shm_key_string, &endPtr, 10);

    if (signal(SIGINT, sigint_handler) == SIG_ERR)
    {
        perror("Unable to catch SIGINT");
        return EXIT_FAILURE;
    }

    int shm_id = shmget(shm_key, SHM_SIZE, IPC_CREAT | 0666);
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

    sem_t *rsem = sem_open(read_semaphore, O_CREAT, S_IRUSR | S_IWUSR, 0);
    sem_t *wsem = sem_open(write_semaphore, O_CREAT, S_IRUSR | S_IWUSR, 1);

    if (rsem == SEM_FAILED || wsem == SEM_FAILED)
    {
        perror("sem_open");
        exit(EXIT_FAILURE);
    }

    strncpy(memory->resem, read_semaphore, sizeof(memory->resem));
    strncpy(memory->wrsem, write_semaphore, sizeof(memory->wrsem));

    int fd;
    int wd;
    char buffer[EVENT_BUFFER_LEN];

    fd = inotify_init();
    if (fd == -1)
    {
        perror("inotify_init");
        exit(1);
    }

    char path[EVENT_BUFFER_LEN];
    snprintf(path, sizeof(path), "../Client/Sources/%s", mount_path);

    wd = inotify_add_watch(fd, path, IN_MODIFY | IN_CREATE | IN_DELETE | IN_ONLYDIR);
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

    sem_unlink(read_semaphore);
    sem_unlink(write_semaphore);

    inotify_rm_watch(fd, wd);
    close(fd);

    return EXIT_SUCCESS;
}
