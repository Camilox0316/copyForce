#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/msg.h>
#include <limits.h>
#include <errno.h>
#include <time.h>

#define MAX_PROCESSES 4
#define MAX_PATH_LEN PATH_MAX
#define BUFFER_SIZE 4096
#define LOG_FILE "copy_log.csv"

struct mensaje {
    long tipoMensaje;
    char directorioOrigen[MAX_PATH_LEN];
    char directorioDestino[MAX_PATH_LEN];
};

int copiarArchivo(const char *rutaOrigen, const char *rutaDestino, FILE *logFile);
void recorrerDirectorio(const char *directorioOrigen, const char *directorioDestino, int qid, FILE *logFile);
void procesoHijoCopiarArchivos(int qid, FILE *logFile);

int copiarArchivo(const char *rutaOrigen, const char *rutaDestino, FILE *logFile) {
    FILE *origen, *destino;
    origen = fopen(rutaOrigen, "rb");
    if (!origen) {
        fprintf(logFile, "%s,Error al abrir el archivo origen\n", rutaOrigen);
        return -1;
    }
    destino = fopen(rutaDestino, "wb");
    if (!destino) {
        fprintf(logFile, "%s,Error al abrir el archivo destino\n", rutaOrigen);
        fclose(origen);
        return -1;
    }

    char buffer[BUFFER_SIZE];
    size_t bytesLeidos;
    long tamanioArchivo = 0;
    clock_t startTime = clock();
    while ((bytesLeidos = fread(buffer, 1, BUFFER_SIZE, origen)) > 0) {
        if (fwrite(buffer, 1, bytesLeidos, destino) != bytesLeidos) {
            fprintf(logFile, "%s,Error al escribir en el archivo destino\n", rutaOrigen);
            fclose(origen);
            fclose(destino);
            return -1;
        }
        tamanioArchivo += bytesLeidos;
    }

    if (ferror(origen)) {
        fprintf(logFile, "%s,Error al leer del archivo origen\n", rutaOrigen);
        fclose(origen);
        fclose(destino);
        return -1;
    }

    fclose(origen);
    fclose(destino);

    clock_t endTime = clock();
    double elapsedTime = (double)(endTime - startTime) / CLOCKS_PER_SEC * 1000.0; // Tiempo en milisegundos
    fprintf(logFile, "%s,%ld,%f,PID %d\n", rutaOrigen, tamanioArchivo, elapsedTime, getpid());
    return 0;
}

void recorrerDirectorio(const char *directorioOrigen, const char *directorioDestino, int qid, FILE *logFile) {
    DIR *dir = opendir(directorioOrigen);
    if (!dir) {
        fprintf(logFile, "%s,Error al abrir el directorio origen\n", directorioOrigen);
        return;
    }

    struct dirent *entrada;
    while ((entrada = readdir(dir)) != NULL) {
        if (strcmp(entrada->d_name, ".") == 0 || strcmp(entrada->d_name, "..") == 0) continue;

        char rutaOrigen[MAX_PATH_LEN];
        snprintf(rutaOrigen, MAX_PATH_LEN, "%s/%s", directorioOrigen, entrada->d_name);
        char rutaDestino[MAX_PATH_LEN];
        snprintf(rutaDestino, MAX_PATH_LEN, "%s/%s", directorioDestino, entrada->d_name);

        struct stat statBuf;
        if (lstat(rutaOrigen, &statBuf) == -1) {
            fprintf(logFile, "%s,Error al obtener información del archivo\n", rutaOrigen);
            continue;
        }

        if (S_ISDIR(statBuf.st_mode)) {
            if (mkdir(rutaDestino, statBuf.st_mode) == -1 && errno != EEXIST) {
                fprintf(logFile, "%s,Error al crear el directorio destino\n", rutaDestino);
                continue;
            }
            recorrerDirectorio(rutaOrigen, rutaDestino, qid, logFile);
        } else {
            struct mensaje msg = {1, "", ""};
            strncpy(msg.directorioOrigen, rutaOrigen, MAX_PATH_LEN);
            strncpy(msg.directorioDestino, rutaDestino, MAX_PATH_LEN);
            if (msgsnd(qid, &msg, sizeof(msg) - sizeof(long), 0) == -1) {
                fprintf(logFile, "%s,Error al enviar el mensaje\n", rutaOrigen);
            }
        }
    }

    if (closedir(dir) == -1) {
        fprintf(logFile, "%s,Error al cerrar el directorio\n", directorioOrigen);
    }
}

void procesoHijoCopiarArchivos(int qid, FILE *logFile) {
    while (1) {
        struct mensaje msg;
        if (msgrcv(qid, &msg, sizeof(msg) - sizeof(long), 0, 0) == -1) {
            fprintf(logFile, "Proceso %d: Error al recibir el mensaje\n", getpid());
            exit(EXIT_FAILURE);
        }

        if (strlen(msg.directorioOrigen) == 0) break; // Mensaje de finalización

        if (copiarArchivo(msg.directorioOrigen, msg.directorioDestino, logFile) != 0) {
            fprintf(logFile, "Proceso %d: Error al copiar el archivo %s -> %s\n", getpid(), msg.directorioOrigen, msg.directorioDestino);
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Uso: %s <directorio_origen> <directorio_destino>\n", argv[0]);
        return EXIT_FAILURE;
    }

    char *directorioOrigen = argv[1];
    char *directorioDestino = argv[2];

    if (mkdir(directorioDestino, 0700) == -1 && errno != EEXIST) {
        perror("Error al crear el directorio destino");
        return EXIT_FAILURE;
    }

    FILE *logFile = fopen(LOG_FILE, "w");
    if (!logFile) {
        perror("Error al crear el archivo de registro");
        return EXIT_FAILURE;
    }
    fprintf(logFile, "Archivo,Tamaño (bytes),Tiempo de copia (ms),Proceso\n");

    key_t key = ftok(".", 'q');
    int qid = msgget(key, IPC_CREAT | 0666);
    if (qid == -1) {
        perror("Error al crear la cola de mensajes");
        fclose(logFile);
        return EXIT_FAILURE;
    }

    for (int i = 0; i < MAX_PROCESSES; ++i) {
        pid_t pid = fork();
        if (pid == 0) {
            procesoHijoCopiarArchivos(qid, logFile);
            exit(EXIT_SUCCESS);
        } else if (pid < 0) {
            perror("Error al crear el proceso hijo");
            fclose(logFile);
            return EXIT_FAILURE;
        }
    }

    printf("Iniciando copia de archivos...\n");
    recorrerDirectorio(directorioOrigen, directorioDestino, qid, logFile);

    struct mensaje msgFinalizacion = {1, "", ""};
    for (int i = 0; i < MAX_PROCESSES; ++i) {
        if (msgsnd(qid, &msgFinalizacion, sizeof(msgFinalizacion) - sizeof(long), 0) == -1) {
            perror("Error al enviar el mensaje de finalización");
            // No se retorna para intentar enviar a todos los procesos
        }
    }

    for (int i = 0; i < MAX_PROCESSES; ++i) {
        wait(NULL);
    }

    printf("Copia de archivos completada.\n");
    printf("Detalles registrados en el archivo %s\n", LOG_FILE);

    if (msgctl(qid, IPC_RMID, NULL) == -1) {
        perror("Error al eliminar la cola de mensajes");
        fclose(logFile);
        return EXIT_FAILURE;
    }

    fclose(logFile);
    return EXIT_SUCCESS;
}