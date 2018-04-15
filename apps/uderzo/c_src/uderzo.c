
#define GLFW_INCLUDE_ES3
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include <nanovg.h>
// OpenGL ES 3 should support the widest array of devices
#define NANOVG_GLES3_IMPLEMENTATION
#include <nanovg_gl.h>
#include <nanovg_gl_utils.h>

#include "uderzo_io.h"

// Comment-driven development.
// [x] 1. Library initialization is done at program startup time.
// [x] 1a.For now, there's one global (vg/gl) context.
// [ ] 2. Everything else is manual.
// [ ] 3. For now, we openly admit to using nanovg, glfw, opengl es
// [ ] 3a.So we directly map functions on the protocol, no translation
// [ ] 3b.This should make code generation simpler, eventually
// [ ] 3c.We also don't wrap pointers. They're just opaque handles on
//        the BEAM side.
// [ ] 4. The render loop is BEAM-side, this code is passive
// [ ] 5. Any GLFW keyboard and mouse events are sent to stdout, async
// [ ] 6. Hence, the stdin/stdout protocol needs to be async
// [ ] 7. Mouse state can also be polled
// [ ] 8. BEAM-side, there should be a concept of flushing so that we
//        can batch commands. This is not visible here.

extern void errorcb(int error, const char *desc);
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

    fprintf(stderr, "Uderzo graphics executable started up.\n");

    read_loop();
}

extern void handle_command(const char *command, unsigned short len);

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

        unsigned short bytes_read = read(STDIN_FILENO, buffer, size);
        if (bytes_read < 0) {
            strerror_r(bytes_read, buffer, BUF_SIZE);
            SEND_ERLANG_ERR(buffer);
        } else if (bytes_read < size) {
            dump_hex(buffer, bytes_read);
            snprintf(buffer, BUF_SIZE, "Expected %d bytes, got %d\n", size, bytes_read);
            SEND_ERLANG_ERR(buffer);
        } else {
            fprintf(stderr, "Handling command of %d bytes, size %d:\n", bytes_read, size);
            dump_hex(buffer, size);
            handle_command(buffer, size);
        }
    }
}

static void _handle_command(const char *command, unsigned short len, int *index);
static void _dispatch_command(const char *buf, unsigned short len, int *index);
void handle_command(const char *command, unsigned short len) {
    int index = 1;
    _handle_command(command, len, &index); // Skip version number
}
static void _handle_command(const char *command, unsigned short len, int *index) {
    // For now, we parse the command, then echo it back.
    // Note that all we accept for now is
    //   {cast, <<function_name>>, args.... [, callback_pid]}
    // Or, preferably, an array of these.
    ei_term term;

    if (*index >= len) {
        fprintf(stderr, "decode done\n");
        return;
    }

    int result = ei_decode_ei_term(command, index, &term);
    fprintf(stderr, "Got result %d index is now 0x%x\n", result, *index);
    assert(result == 1);
    fprintf(stderr, "Got term type %c / %d\n", term.ei_type, term.ei_type);
    switch (term.ei_type) {
    case ERL_SMALL_TUPLE_EXT:
        assert(term.arity == 2);
        _dispatch_command(command, len, index);
        _handle_command(command, len, index);
        break;
    case ERL_LIST_EXT:
        // A list of commands; we can send this for efficiency. Loop and go.
        fprintf(stderr, "Handling list is arity %d\n", term.arity);
        for (int i = 0; i < term.arity; i++) {
            _handle_command(command, len, index);
        }
        break;
    case ERL_NIL_EXT:
        fprintf(stderr, "Skip nil\n");
        break;
    default:
        fprintf(stderr, "Unknown term type %c / %d\n", term.ei_type, term.ei_type);
        assert(1 == 0);
    }

    // However, to get started, just echo:
    // write_response_bytes(command, len);
}
static void _dispatch_comment(const char *buf, unsigned short len, int *index);
static void _dispatch_window(const char *buf, unsigned short len, int *index);
static void _dispatch_on_frame(const char *buf, unsigned short len, int *index);
static void _dispatch_command(const char *buf, unsigned short len, int *index) {
    char atom[MAXATOMLEN];
    assert(ei_decode_atom(buf, index, atom) == 0);
    fprintf(stderr, "Dispatching %s\n", atom);
    if (strncmp("comment", atom, 7) == 0) {
        _dispatch_comment(buf, len, index);
    } else if (strncmp("window", atom, 6) == 0) {
        _dispatch_window(buf, len, index);
    } else if (strncmp("on_frame", atom, 6) == 0) {
        _dispatch_on_frame(buf, len, index);
    } else {
        fprintf(stderr, "Unknown thing %s\n", atom);
        assert(1 == 0);
    }
}
// {comment, <<comment>>}
static void _dispatch_comment(const char *buf, unsigned short len, int *index) {
    char comment[BUF_SIZE];
    long length;
    assert(ei_decode_binary(buf, index, comment, &length) == 0);
    fprintf(stderr, "Got comment [%s]\n", comment);
}
// {window, [width, height, <<title>>]}
static void _dispatch_window(const char *buf, unsigned short len, int *index) {
    char title[BUF_SIZE];
    long length, width, height;
    ei_term term;

    assert(ei_decode_ei_term(buf, index, &term));
    assert(term.arity == 3);
    assert(ei_decode_long(buf, index, &width) == 0);
    assert(ei_decode_long(buf, index, &height) == 0);
    assert(ei_decode_binary(buf, index, title, &length) == 0);
    fprintf(stderr, "Got window (%ld, %ld, [%s])\n", width, height, title);
}
// {on_frame, pid}
static void _dispatch_on_frame(const char *buf, unsigned short len, int *index) {
    erlang_pid pid;
    assert(ei_decode_pid(buf, index, &pid) == 0);
    fprintf(stderr, "On frame callback pid <<%d.%d.%d@%s>>\n",
            pid.num, pid.serial, pid.creation, pid.node);
}

void errorcb(int error, const char *desc) {
    // TODO proper callback on stdout as well.
    fprintf(stderr, "GLFW error %d: %s\n", error, desc);
}
