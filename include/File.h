#ifndef FILE_H
#define FILE_H
#endif

template <const char * FileExt>
extern int FileFilter(const struct dirent *ent)
{
    unsigned char type;
    char * name;
    char * ext;
    size_t len;

    type = ent->d_type;
    if (type == DT_DIR)
        return 1;
    else if (type != DT_REG)
        return 0;
    name = (char *) ent->d_name;
    len = strlen(name);
    ext = name + len - 3;
    return strcoll(ext, (FileExt)) == 0;
}

extern int ScanDirectory(const char * dirpath,
        int (*__FileFilter) (__const struct dirent *),
        int (*__Callback) (__const char * filepath))
    __nonnull ((1, 2));
