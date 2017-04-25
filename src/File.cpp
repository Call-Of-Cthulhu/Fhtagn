/*
 * Author   : KaiserKatze
 * Date     : 2017-4-25
 * License  : GPLv3
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dirent.h>
#include <linux/limits.h>
#include <sys/types.h>
#include <sys/dir.h>
#include <unistd.h>

#include "File.h"

#define SEPARATOR '/'
#define FS_DEPTH 128

static int join(char * dst, char * dir, char * ent)
{
    size_t len;

    memset(dst, 0, PATH_MAX);
    len = strlen(dir);
    strcpy(dst, dir);
    if (dir[len - 1] != SEPARATOR)
        dst[len++] = SEPARATOR;
    strcpy(dst + len, ent);

    return len;
}

extern int ScanDirectory(const char * rootdir,
        int (*__FileFilter) (__const struct dirent *),
        int (*__Callback) (__const char * filepath))
{
    int count;
    FILE * file;
    int depth;
    char dirs[FS_DEPTH][PATH_MAX];
    char dirpath[PATH_MAX];
    struct dirent ** namelist;
    unsigned char d_type;
    char * d_name;
    char path[PATH_MAX];

    // init
    strcpy(dirs[0], rootdir);
    depth = 1;
    // scan
    while (depth--)
    {
        printf("====================================\n");
        strcpy(dirpath, dirs[depth]);
        namelist = NULL;
        count = scandir(dirpath, &namelist, __FileFilter, alphasort);
        if (count < 0)
        {
            fprintf(stderr, "Fail to scan dir: %s\n", dirpath);
            if (namelist)
            {
                fprintf(stderr, "Dispose 'namelist'\n");
                free(namelist);
                namelist = NULL;
            }
            continue;
        }
        printf("Traverse directory '%s'\n", dirpath);
        printf("------------------------------------\n");
        while (count--)
        {
            d_type = namelist[count]->d_type;
            d_name = namelist[count]->d_name;
            // skip '.' and '..'
            if (d_name[0] == '.')
                continue;
            join(path, dirpath, d_name);
            // direcotry
            if (d_type == DT_DIR)
                strcpy(dirs[depth++], path);
            // file
            else if (d_type == DT_REG)
                __Callback(path);
            // free current entry
            free(namelist[count]);
        }
        // free entry list
        free(namelist);
        namelist = NULL;
    }
    printf("====================================\n");

    return EXIT_SUCCESS;
}
