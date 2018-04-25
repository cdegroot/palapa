// -*- mode: c; -*-

/*
 * This is the Clixir header that is put on top of the generated
 * code. It should contain
 * a) includes needed for the generated code;
 * b) a main method
 * c) any other stuff you can think off ;-)
 */

// OpenGL ES 3 should support the widest array of devices. One
// clear target is RPi with a framebuffer-to-gpio-display mirror.
#define GLFW_INCLUDE_ES3
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include <nanovg.h>
#define NANOVG_GLES3_IMPLEMENTATION
#include <nanovg_gl.h>
#include <nanovg_gl_utils.h>

#include "clixir_support.h"

// Comment-driven development.
// [x] 1. Library initialization is done at program startup time.
// [x] 1a.For now, there's one global (vg/gl) context.
// [x] 2. Everything else is manual.
// [x] 3. For now, we openly admit to using nanovg, glfw, opengl es
// [x] 3a.So we directly map functions on the protocol, no translation
// [x] 3b.This should make code generation simpler, eventually
// [x] 3c.We also don't wrap pointers. They're just opaque handles on
//        the BEAM side.
// [x] 4. The render loop is BEAM-side, this code is passive
// [ ] 5. Any GLFW keyboard and mouse events are sent to stdout, async
// [ ] 6. Hence, the stdin/stdout protocol needs to be async
// [ ] 7. Mouse state can also be polled
// [ ] 8. BEAM-side, there should be a concept of flushing so that we
//        can batch commands. This is not visible here.

extern void errorcb(int error, const char *desc);
//extern void key_callback(GLFWwindow *window, int key, int scancode, int action, int mods);
extern void read_loop();

// These pesky global things, for now.
NVGcontext* vg = NULL;
//erlang_pid key_callback_pid; // etcetera for all the GLFW callbacks?

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

    clixir_read_loop();
}

void errorcb(int error, const char *desc) {
    // TODO proper callback on stdout as well.
    fprintf(stderr, "GLFW error %d: %s\n", error, desc);
    // For now, just crash.
    assert(0);
}

// End of manually maintained header. Generated code follows below.


// END OF HEADER


// Generated code for glfw_destroy_window do not edit!
static void _dispatch_glfw_destroy_window(const char *buf, unsigned short len, int *index) {
    GLFWwindow * window;
    assert(ei_decode_longlong(buf, index, (long long *) &window) == 0);
    glfwDestroyWindow(window);
}

// Generated code for glfw_create_window do not edit!
static void _dispatch_glfw_create_window(const char *buf, unsigned short len, int *index) {
    long height;
    long length;
    erlang_pid pid;
    char title[BUF_SIZE];
    long title_len;
    long width;
    GLFWwindow * window;
    assert(ei_decode_long(buf, index, &width) == 0);
    assert(ei_decode_long(buf, index, &height) == 0);
    assert(ei_decode_binary(buf, index, title, &title_len) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    window = glfwCreateWindow(width, height, title, NULL, NULL);
    glfwMakeContextCurrent(window);
    glfwSwapInterval(0);
    if (vg == NULL) {
        vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
        assert(vg != NULL);
    }
    if (window != NULL) {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);

        ei_encode_atom(response, &response_index, "ok");
        ei_encode_longlong(response, &response_index, (long long) window);
        write_response_bytes(response, response_index);
    } else {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);

        ei_encode_atom(response, &response_index, "error");
        ei_encode_atom(response, &response_index, "Could not create window");
        write_response_bytes(response, response_index);
    }
}

// Generated code for comment do not edit!
static void _dispatch_comment(const char *buf, unsigned short len, int *index) {
    char comment[BUF_SIZE];
    long comment_len;
    assert(ei_decode_binary(buf, index, comment, &comment_len) == 0);
    fprintf(stderr, "Got comment [%s]", comment);
}

/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--576460752303423484.gperf  */
/* Computed positions: -k'' */

#line 1 "/tmp/clixir-temp-nonode@nohost--576460752303423484.gperf"
struct dispatch_entry {
  char *name;
  void (*dispatch_func)(const char *buf, unsigned short len, int *index);
};

#define TOTAL_KEYWORDS 3
#define MIN_WORD_LENGTH 7
#define MAX_WORD_LENGTH 19
#define MIN_HASH_VALUE 7
#define MAX_HASH_VALUE 19
/* maximum key range = 13, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
/*ARGSUSED*/
static unsigned int
hash (register const char *str, register size_t len)
{
  return len;
}

struct dispatch_entry *
in_word_set (register const char *str, register size_t len)
{
  static struct dispatch_entry wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 8 "/tmp/clixir-temp-nonode@nohost--576460752303423484.gperf"
      {"comment", _dispatch_comment},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""},
#line 7 "/tmp/clixir-temp-nonode@nohost--576460752303423484.gperf"
      {"glfw_create_window", _dispatch_glfw_create_window},
#line 6 "/tmp/clixir-temp-nonode@nohost--576460752303423484.gperf"
      {"glfw_destroy_window", _dispatch_glfw_destroy_window}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register unsigned int key = hash (str, len);

      if (key <= MAX_HASH_VALUE)
        {
          register const char *s = wordlist[key].name;

          if (*str == *s && !strcmp (str + 1, s + 1))
            return &wordlist[key];
        }
    }
  return 0;
}

void _dispatch_command(const char *buf, unsigned short len, int *index) {
    char atom[MAXATOMLEN];
    struct dispatch_entry *dpe;
    assert(ei_decode_atom(buf, index, atom) == 0);

    dpe = in_word_set(atom, strlen(atom));
    if (dpe != NULL) {
         (dpe->dispatch_func)(buf, len, index);
    } else {
        fprintf(stderr, "Dispatch function not found for [%s]\
", atom);
    }
}

