
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/uio.h>
#define GLFW_INCLUDE_ES3
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include <nanovg.h>
// OpenGL ES 3 should support the widest array of devices
#define NANOVG_GLES3_IMPLEMENTATION
#include <nanovg_gl.h>
#include <nanovg_gl_utils.h>

#include <erl_interface.h> // or ei.h? No clue so far.

// Comment-driven development.
// 1. Library initialization is done at program startup time.
// 1a.For now, there's one global (vg/gl) context.
// 2. Everything else is manual.
// 3. For now, we openly admit to using nanovg, glfw, opengl es
// 3a.So we directly map functions on the protocol, no translation
// 3b.This should make code generation simpler, eventually
// 3c.We also don't wrap pointers. They're just opaque handles on
//    the BEAM side.
// 4. The render loop is BEAM-side, this code is passive
// 5. Any GLFW keyboard and mouse events are sent to stdout, async
// 6. Hence, the stdin/stdout protocol needs to be async
// 7. Mouse state can also be polled
// 8. BEAM-side, there should be a concept of flushing so that we
//    can batch commands. This is not visible here.

#define BUF_SIZE 65536 // we try to fit most of our shit in here until proven wrong.

#define SEND_ERLANG_OK     write_single_atom("ok")
#define SEND_ERLANG_ERR(x) write_response_tuple2("error", x)

extern void errorcb(int error, const char *desc);
extern void write_single_atom(char *atom);
extern void write_response_tuple2(char *atom, char *message);
extern void write_response_bytes(char *data, unsigned short len);
extern void read_loop();

// These pesky global things, for now.
NVGcontext* vg = NULL;

int main() {
    if (!glfwInit()) {
        SEND_ERLANG_ERR("Failed to init GLFW.");
        return -1;
    }

    glfwSetErrorCallback(errorcb);

    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    SEND_ERLANG_OK;

    read_loop();
}

void handle_command(char *command, unsigned short len);
void read_loop() {
    // Protocol: 2 bytes with big endian length, then the actual command.
    // So maximum size we can read is 65535. We're not even gonna allocate
    // that with today's stack sizes and a single process. Once we start pushing
    // large graphics objects like bitmaps through the pipe, we'll regret the
    // decision but maybe by then we have converted this to a full C node.
    char buffer[BUF_SIZE];
    unsigned char size_buffer[2];

    while (1) { // TODO how do we end the fun?
        assert(read(STDIN_FILENO, size_buffer, 2) == 2);
        unsigned short size = (size_buffer[0] << 8) + size_buffer[1];

        unsigned short bytes_read = read(STDIN_FILENO, buffer, BUF_SIZE);
        if (bytes_read < 0) {
            strerror_r(bytes_read, buffer, BUF_SIZE);
            SEND_ERLANG_ERR(buffer);
        } else if (bytes_read < size) {
            SEND_ERLANG_ERR("Read less bytes than expected");
        } else {
            handle_command(buffer, bytes_read);
        }
    }
}


void handle_command(char *command, unsigned short len) {
    // For now, we parse the command, then echo it back.
    // Note that all we accept for now is
    //   {cast, <<function_name>>, args.... [, callback_pid]}

    // However, to get started, just echo:
    write_response_bytes(command, len);
}

void write_single_atom(char *atom) {
    char buffer[MAXATOMLEN];
    int index = 0;

    ei_encode_atom(buffer, &index, atom);

    write_response_bytes(buffer, index);
}

// Not entirely correctly named, but usually what we want - an {atom, binary} 2-tuple
void write_response_tuple2(char *atom, char *message) {
    char buffer[BUF_SIZE];
    int index = 0;

    ei_encode_tuple_header(buffer, &index, 2);
    ei_encode_atom(buffer, &index, atom);
    ei_encode_binary(buffer, &index, message, strlen(message));

    write_response_bytes(buffer, index);
}

void write_response_bytes(char *bytes, unsigned short len) {
    struct iovec iov[2];
    unsigned char size_buffer[2];

    size_buffer[0] = len >> 8;
    size_buffer[1] = len & 0xff;

    iov[0].iov_base = size_buffer;
    iov[0].iov_len  = 2;
    iov[1].iov_base = bytes;
    iov[1].iov_len  = len;

    assert (writev(STDOUT_FILENO, iov, 2) == len + 2);
}

void errorcb(int error, const char *desc) {
    // TODO proper callback on stdout as well.
    fprintf(stderr, "GLFW error %d: %s\n", error, desc);
}
