/*
  GPL-2+ ("and any later version")
  Kai Lüke 2020
*/

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

static const char * const folder = "/etc/systemd/system/system-wake-up.timer.d";
static const char * const prefix = "10-";
static const char * const suffix = ".conf";
static char * unit = "[Timer]\n";
static const int bufsize = 1024;

int write_all(int fd, char * buf, size_t len) {
  int r = 0;
  int written = 0;
  while (r = write(fd, buf + written, len - written), r < 0 || written < len) {
    if (r < 0 && errno != EINTR) {
      perror("Could not write to file");
      return -1;
    }
    if (r > 0) {
      written += r;
    }
    if (written == len) {
      return 0;
    }
  }
  return 0;
}

int execute(char * prog, char ** arg) {
  int p = fork();
  int w = 0;
  switch (p) {
    case 0: /* child */
      if (execvp(prog, arg)) {
        perror("Error executing");
        return -1;
      }
      break;
   case -1:
     perror("Error forking");
     return -1;
     break;
   default:
     if (waitpid(p, &w, 0) == -1) {
       perror("Error waiting");
       return -1;
     }
     if (!WIFEXITED(w) || WEXITSTATUS(w) != 0) {
       printf("Unexpected return code, crash, or failure to execute\n");
       return -1;
     }
     break;
  }
  return 0;
}

/* this is a setuid helper binary but it could also be done with polkit or a (D-Bus) daemon */
int main(int argc, char **argv) {
  if (putenv("PATH=/usr/bin:/usr/sbin:/bin/:/sbin")) { /* Prevent running a different systemctl binary */
    perror("Error sanitizing PATH");
    return -1;
  }
  if (argc > 1 && (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
    printf("Usage: %s ARGS...\n", argv[0]);
    printf("Update the drop-in file %s/%sUSER%s with OnCalendar=ARG1, ... values.\n", folder, prefix, suffix);
    printf("When no argument is given, an empty unit will be written out.\n");
    printf("Only a numeric format for the value can be given, like \"%%Y-%%m-%%d %%H:%%M:%%S\" or \"@UNIXTIME\".\n");
    return -1;
  }
  const char * const user = getlogin();
  if (user == NULL) {
    perror("Could not get real user name");
    return -1;
  }
  if ((mkdir("/etc", 0755) && errno != EEXIST) || (mkdir("/etc/systemd", 0755) && errno != EEXIST) || (mkdir("/etc/systemd/system", 0755) && errno != EEXIST) || (mkdir(folder, 0755) && errno != EEXIST)) {
    perror("Could not create directory");
    return -1;
  }
  char * file = malloc(bufsize);
  if (file == NULL) {
    perror("Could not allocate");
    return -1;
  }
  snprintf(file, bufsize, "%s/%s%s%s", folder, prefix, user, suffix);
  file[bufsize - 1] = '\0';
  int f = -1;
  while (f = open(file, O_CREAT | O_WRONLY | O_TRUNC, 0644), f < 0) {
    if (errno != EINTR) {
      perror("Could not open file");
      free(file);
      return -1;
    }
  }
  free(file);
  if (write_all(f, unit, strlen(unit))) {
    return -1;
  }
  char * line = malloc(bufsize);
  if (line == NULL) {
    perror("Could not allocate");
    return -1;
  }
  char * sanitized = malloc(bufsize);
  if (sanitized == NULL) {
    perror("Could not allocate");
    free(line);
    return -1;
  }
  for (int i = 1; i < argc; i++) {
    int skip = 0;
    sanitized[0] = '\0';
    for (int j = 0; j < strlen(argv[i]) && j < bufsize - 1; j++) {
      switch(argv[i][j]) {
        case ' ':
        case '-':
        case '0':
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
        case ':':
        case '@':
          sanitized[j] = argv[i][j];
          sanitized[j + 1] = '\0';
          break;
        default:
          printf("Unexpected character in argument (only digits, minus, colon, and space are allowed)");
          skip = 1;
          break;
      }
    }
    if (skip) {
      continue;
    }
    snprintf(line, bufsize, "OnCalendar=%s\n", sanitized);
    line[bufsize - 1] = '\0';
    if (write_all(f, line, strlen(line))) {
      free(line);
      free(sanitized);
      return -1;
    }
  }
  free(line);
  free(sanitized);
  while (close(f) < 0) {
    if (errno != EINTR) {
      perror("Could not close file");
      return -1;
    }
  }
  char * reload_args[] = {"systemctl", "daemon-reload", NULL};
  if (execute("systemctl", reload_args)) {
    return -1;
  }
  char * enable_args[] = {"systemctl", "enable", "system-wake-up.timer", NULL};
  if (execute("systemctl", enable_args)) {
    return -1;
  }
  char * restart_args[] = {"systemctl", "restart", "system-wake-up.timer", NULL};
  if (execute("systemctl", restart_args)) {
    return -1;
  }
  return 0;
}
