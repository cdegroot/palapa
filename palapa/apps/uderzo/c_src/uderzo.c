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
#ifdef UDERZO_VC
#  include <bcm_host.h>
#  include <GLES2/gl2.h>
#  include <GLES2/gl2ext.h>
#  include <EGL/egl.h>
#  include <EGL/eglext.h>
#else
#  define GLFW_INCLUDE_ES2
#  define GLFW_INCLUDE_GLEXT
#  include <GLFW/glfw3.h>
#endif

#include <nanovg.h>
#define NANOVG_GLES2_IMPLEMENTATION
#include <nanovg_gl.h>
#include <nanovg_gl_utils.h>

#include "clixir_support.h"
#include "nanovg_demo.h"

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
DemoData data;
//erlang_pid key_callback_pid; // etcetera for all the GLFW callbacks?

int main() {

#ifdef UDERZO_VC
    // TODO setup for RPi3
#else
    if (!glfwInit()) {
        SEND_ERLANG_ERR("Failed to init GLFW.");
        return -1;
    }

    glfwSetErrorCallback(errorcb);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
#endif

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


// Generated code for draw_eyes do not edit!
static void _dispatch_draw_eyes(const char *buf, unsigned short len, int *index) {
    double h;
    double mx;
    double my;
    double t;
    double w;
    double x;
    double y;
    assert(ei_decode_double(buf, index, &x) == 0);
    assert(ei_decode_double(buf, index, &y) == 0);
    assert(ei_decode_double(buf, index, &w) == 0);
    assert(ei_decode_double(buf, index, &h) == 0);
    assert(ei_decode_double(buf, index, &mx) == 0);
    assert(ei_decode_double(buf, index, &my) == 0);
    assert(ei_decode_double(buf, index, &t) == 0);
    drawEyes(vg, x, y, w, h, mx, my, t);
}

// Generated code for demo_render do not edit!
static void _dispatch_demo_render(const char *buf, unsigned short len, int *index) {
    double height;
    double mx;
    double my;
    double t;
    double width;
    assert(ei_decode_double(buf, index, &mx) == 0);
    assert(ei_decode_double(buf, index, &my) == 0);
    assert(ei_decode_double(buf, index, &width) == 0);
    assert(ei_decode_double(buf, index, &height) == 0);
    assert(ei_decode_double(buf, index, &t) == 0);
    renderDemo(vg, mx, my, width, height, t, 0, &data);
}

// Generated code for uderzo_end_frame do not edit!
static void _dispatch_uderzo_end_frame(const char *buf, unsigned short len, int *index) {
    erlang_pid pid;
    long window;
    assert(ei_decode_long(buf, index, &window) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
}

// Generated code for uderzo_start_frame do not edit!
static void _dispatch_uderzo_start_frame(const char *buf, unsigned short len, int *index) {
    erlang_pid pid;
    long window;
    assert(ei_decode_long(buf, index, &window) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    char response[BUF_SIZE];
    int response_index = 0;
    ei_encode_version(response, &response_index);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_pid(response, &response_index, &pid);
    ei_encode_tuple_header(response, &response_index, 5);
    ei_encode_atom(response, &response_index, "uderzo_start_frame_result");
    ei_encode_atom(response, &response_index, "0.0");
    ei_encode_atom(response, &response_index, "0.0");
    ei_encode_atom(response, &response_index, "1920.0");
    ei_encode_atom(response, &response_index, "1080.0");
    write_response_bytes(response, response_index);
}

// Generated code for glfw_destroy_window do not edit!
static void _dispatch_glfw_destroy_window(const char *buf, unsigned short len, int *index) {
    long window;
    assert(ei_decode_long(buf, index, &window) == 0);
    assert(window == 42);
}

// Generated code for glfw_create_window do not edit!
static void _dispatch_glfw_create_window(const char *buf, unsigned short len, int *index) {
    long height;
    long length;
    erlang_pid pid;
    char title[BUF_SIZE];
    long title_len;
    long width;
    assert(ei_decode_long(buf, index, &width) == 0);
    assert(ei_decode_long(buf, index, &height) == 0);
    assert(ei_decode_binary(buf, index, title, &title_len) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    char response[BUF_SIZE];
    int response_index = 0;
    ei_encode_version(response, &response_index);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_pid(response, &response_index, &pid);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_atom(response, &response_index, "glfw_create_window_result");
    ei_encode_atom(response, &response_index, "42");
    write_response_bytes(response, response_index);
}

// Generated code for comment do not edit!
static void _dispatch_comment(const char *buf, unsigned short len, int *index) {
    char comment[BUF_SIZE];
    long comment_len;
    assert(ei_decode_binary(buf, index, comment, &comment_len) == 0);
    fprintf(stderr, "Got comment [%s]", comment);
}

/* C code produced by gperf version 3.0.4 */
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--134217407.gperf  */
/* Computed positions: -k'1' */

#if !((' ' == 32) && ('!' == 33) && ('"' == 34) && ('#' == 35) \
      && ('%' == 37) && ('&' == 38) && ('\'' == 39) && ('(' == 40) \
      && (')' == 41) && ('*' == 42) && ('+' == 43) && (',' == 44) \
      && ('-' == 45) && ('.' == 46) && ('/' == 47) && ('0' == 48) \
      && ('1' == 49) && ('2' == 50) && ('3' == 51) && ('4' == 52) \
      && ('5' == 53) && ('6' == 54) && ('7' == 55) && ('8' == 56) \
      && ('9' == 57) && (':' == 58) && (';' == 59) && ('<' == 60) \
      && ('=' == 61) && ('>' == 62) && ('?' == 63) && ('A' == 65) \
      && ('B' == 66) && ('C' == 67) && ('D' == 68) && ('E' == 69) \
      && ('F' == 70) && ('G' == 71) && ('H' == 72) && ('I' == 73) \
      && ('J' == 74) && ('K' == 75) && ('L' == 76) && ('M' == 77) \
      && ('N' == 78) && ('O' == 79) && ('P' == 80) && ('Q' == 81) \
      && ('R' == 82) && ('S' == 83) && ('T' == 84) && ('U' == 85) \
      && ('V' == 86) && ('W' == 87) && ('X' == 88) && ('Y' == 89) \
      && ('Z' == 90) && ('[' == 91) && ('\\' == 92) && (']' == 93) \
      && ('^' == 94) && ('_' == 95) && ('a' == 97) && ('b' == 98) \
      && ('c' == 99) && ('d' == 100) && ('e' == 101) && ('f' == 102) \
      && ('g' == 103) && ('h' == 104) && ('i' == 105) && ('j' == 106) \
      && ('k' == 107) && ('l' == 108) && ('m' == 109) && ('n' == 110) \
      && ('o' == 111) && ('p' == 112) && ('q' == 113) && ('r' == 114) \
      && ('s' == 115) && ('t' == 116) && ('u' == 117) && ('v' == 118) \
      && ('w' == 119) && ('x' == 120) && ('y' == 121) && ('z' == 122) \
      && ('{' == 123) && ('|' == 124) && ('}' == 125) && ('~' == 126))
/* The character set is not based on ISO-646.  */
error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gnu-gperf@gnu.org>."
#endif

#line 1 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
struct dispatch_entry {
  char *name;
  void (*dispatch_func)(const char *buf, unsigned short len, int *index);
};

#define TOTAL_KEYWORDS 7
#define MIN_WORD_LENGTH 7
#define MAX_WORD_LENGTH 19
#define MIN_HASH_VALUE 7
#define MAX_HASH_VALUE 24
/* maximum key range = 18, duplicates = 0 */

#ifdef __GNUC__
__inline
#else
#ifdef __cplusplus
inline
#endif
#endif
static unsigned int
hash (str, len)
     register const char *str;
     register unsigned int len;
{
  static unsigned char asso_values[] =
    {
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25,  0,
       0, 25, 25,  5, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25,  0, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
      25, 25, 25, 25, 25, 25
    };
  return len + asso_values[(unsigned char)str[0]];
}

#ifdef __GNUC__
__inline
#if defined __GNUC_STDC_INLINE__ || defined __GNUC_GNU_INLINE__
__attribute__ ((__gnu_inline__))
#endif
#endif
struct dispatch_entry *
in_word_set (str, len)
     register const char *str;
     register unsigned int len;
{
  static struct dispatch_entry wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 12 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"comment", _dispatch_comment},
      {""},
#line 6 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"draw_eyes", _dispatch_draw_eyes},
      {""},
#line 7 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"demo_render", _dispatch_demo_render},
      {""}, {""}, {""}, {""},
#line 8 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"uderzo_end_frame", _dispatch_uderzo_end_frame},
      {""},
#line 9 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"uderzo_start_frame", _dispatch_uderzo_start_frame},
      {""}, {""}, {""}, {""},
#line 11 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"glfw_create_window", _dispatch_glfw_create_window},
#line 10 "/tmp/clixir-temp-nonode@nohost--134217407.gperf"
      {"glfw_destroy_window", _dispatch_glfw_destroy_window}
    };

  if (len <= MAX_WORD_LENGTH && len >= MIN_WORD_LENGTH)
    {
      register int key = hash (str, len);

      if (key <= MAX_HASH_VALUE && key >= 0)
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

