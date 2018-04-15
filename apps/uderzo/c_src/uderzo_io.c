/*
 *  uderzo I/O functions.
 *
 *  The stuff that talks to BEAM lives here.
 */
#include "uderzo_io.h"

void write_single_atom(const char *atom) {
    char buffer[MAXATOMLEN];
    int index = 0;

    ei_encode_atom(buffer, &index, atom);

    write_response_bytes(buffer, index);
}

// Not entirely correctly named, but usually what we want - an {atom, binary} 2-tuple
void write_response_tuple2(const char *atom, const char *message) {
    char buffer[BUF_SIZE];
    int index = 0;

    ei_encode_tuple_header(buffer, &index, 2);
    ei_encode_atom(buffer, &index, atom);
    ei_encode_binary(buffer, &index, message, strlen(message));

    write_response_bytes(buffer, index);
}

void write_response_bytes(const char *bytes, unsigned short len) {
    struct iovec iov[2];
    unsigned char size_buffer[2];

    size_buffer[0] = len >> 8;
    size_buffer[1] = len & 0xff;

    iov[0].iov_base = size_buffer;
    iov[0].iov_len  = 2;
    iov[1].iov_base = (char *) bytes; // ok to drop the const here, read-only access
    iov[1].iov_len  = len;

    fprintf(stderr, "Writing response bytes:\n");
    dump_hex(size_buffer, 2);
    dump_hex(bytes, len);
    assert (writev(STDOUT_FILENO, iov, 2) == len + 2);
    fprintf(stderr, "Wrote response bytes\n");
}

// For debugging, shamely stolen from github
// https://gist.githubusercontent.com/ccbrown/9722406/raw/05202cd8f86159ff09edc879b70b5ac6be5d25d0/DumpHex.c

void dump_hex(const void* data, size_t size) {
    char ascii[17];
    size_t i, j;
    ascii[16] = '\0';
    for (i = 0; i < size; ++i) {
        fprintf(stderr,"%02X ", ((unsigned char*)data)[i]);
        if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
            ascii[i % 16] = ((unsigned char*)data)[i];
        } else {
            ascii[i % 16] = '.';
        }
        if ((i+1) % 8 == 0 || i+1 == size) {
            fprintf(stderr," ");
            if ((i+1) % 16 == 0) {
                fprintf(stderr,"|  %s \n", ascii);
            } else if (i+1 == size) {
                ascii[(i+1) % 16] = '\0';
                if ((i+1) % 16 <= 8) {
                    fprintf(stderr," ");
                }
                for (j = (i+1) % 16; j < 16; ++j) {
                    fprintf(stderr,"   ");
                }
                fprintf(stderr,"|  %s \n", ascii);
            }
        }
    }
    fflush(stderr);
}
