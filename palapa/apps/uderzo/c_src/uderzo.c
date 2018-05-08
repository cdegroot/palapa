#line 1 "c_src/uderzo.hx"// -*- mode: c; -*-

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

// For now we simply use the state structure from the VC example, whittle away
// what we don't need. 
#ifdef UDERZO_VC
typedef struct
{
   uint32_t screen_width;
   uint32_t screen_height;
// OpenGL|ES objects
   DISPMANX_DISPLAY_HANDLE_T dispman_display;
   DISPMANX_ELEMENT_HANDLE_T dispman_element;
   EGLDisplay display;
   EGLSurface surface;
   EGLContext context;
   GLuint tex[6];
// model rotation vector and direction
   GLfloat rot_angle_x_inc;
   GLfloat rot_angle_y_inc;
   GLfloat rot_angle_z_inc;
// current model rotation angles
   GLfloat rot_angle_x;
   GLfloat rot_angle_y;
   GLfloat rot_angle_z;
// current distance from camera
   GLfloat distance;
   GLfloat distance_inc;
// pointers to texture buffers
   char *tex_buf1;
   char *tex_buf2;
   char *tex_buf3;
} CUBE_STATE_T;

// Define one global. "One display should be enough for everybody" - Bill G.
CUBE_STATE_T state;
#endif

extern void errorcb(int error, const char *desc);
//extern void key_callback(GLFWwindow *window, int key, int scancode, int action, int mods);
extern void read_loop();

// These pesky global things, for now.
NVGcontext* vg = NULL;
DemoData data;
//erlang_pid key_callback_pid; // etcetera for all the GLFW callbacks?

int main() {
  //char name[256];
  //snprintf(name, 256, "/tmp/mtrace.%d", getpid());
  //setenv("MALLOC_TRACE", name, 1);
  //setenv("MALLOC_TRACE", "/dev/stderr", 1);
  //mtrace();

#ifdef UDERZO_VC
   // Stolen from the hello triangle sample
   int32_t success = 0;
   EGLBoolean result;
   EGLint num_config;

   static EGL_DISPMANX_WINDOW_T nativewindow;

   DISPMANX_UPDATE_HANDLE_T dispman_update;
   VC_RECT_T dst_rect;
   VC_RECT_T src_rect;

   static const EGLint attribute_list[] = {
      EGL_RED_SIZE, 8,
      EGL_GREEN_SIZE, 8,
      EGL_BLUE_SIZE, 8,
      EGL_ALPHA_SIZE, 8,
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_NONE
   };
   static const EGLint context_attributes[] = {
     EGL_CONTEXT_CLIENT_VERSION, 2, 
     EGL_NONE
   };
   
   EGLConfig config;
 
   bcm_host_init();
   memset(&state, 0, sizeof(state));

   // get an EGL display connection
   state.display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
   assert(state.display != EGL_NO_DISPLAY);

   // initialize the EGL display connection
   result = eglInitialize(state.display, NULL, NULL);
   assert(EGL_FALSE != result);

   // get an appropriate EGL frame buffer configuration
   result = eglChooseConfig(state.display, attribute_list, &config, 1, &num_config);
   assert(EGL_FALSE != result);

   result = eglBindAPI(EGL_OPENGL_ES_API);
   assert(EGL_FALSE != result);

   state.context = eglCreateContext(state.display, config, EGL_NO_CONTEXT, context_attributes);
   assert(state.context != EGL_NO_CONTEXT);

   // create an EGL window surface
   success = graphics_get_display_size(0 /* LCD */, &state.screen_width, &state.screen_height);
   assert(success >= 0);

   fprintf(stderr, "Raspberry screen size %d by %d\n", state.screen_width, state.screen_height);

   dst_rect.x = 0;
   dst_rect.y = 0;
   dst_rect.width = state.screen_width;
   dst_rect.height = state.screen_height;
      
   src_rect.x = 0;
   src_rect.y = 0;
   src_rect.width = state.screen_width << 16;
   src_rect.height = state.screen_height << 16;        

   state.dispman_display = vc_dispmanx_display_open(0 /* LCD */);
   dispman_update = vc_dispmanx_update_start(0);
         
   state.dispman_element = vc_dispmanx_element_add (dispman_update, state.dispman_display,
      0/*layer*/, &dst_rect, 0/*src*/,
      &src_rect, DISPMANX_PROTECTION_NONE, 0 /*alpha*/, 0/*clamp*/, 0/*transform*/);
      
   nativewindow.element = state.dispman_element;
   nativewindow.width = state.screen_width;
   nativewindow.height = state.screen_height;
   vc_dispmanx_update_submit_sync(dispman_update);

   state.surface = eglCreateWindowSurface(state.display, config, &nativewindow, NULL);
   assert(state.surface != EGL_NO_SURFACE);

   // connect the context to the surface
   result = eglMakeCurrent(state.display, state.surface, state.surface, state.context);
   assert(EGL_FALSE != result);

   // Set background color and clear buffers
   glClearColor(0.15f, 0.25f, 0.35f, 1.0f);

   // Enable back face culling. Why?
   //glEnable(GL_CULL_FACE);

   glClearColor(0.15, 0.25, 0.35, 1.0);
   glClear(GL_COLOR_BUFFER_BIT);
   assert(glGetError() == 0);

   // Not in GLES2? TODO check glMatrixMode(GL_MODELVIEW);

   vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
   assert(vg != NULL);
   loadDemoData(vg, &data);

#else
    if (!glfwInit()) {
        SEND_ERLANG_ERR("Failed to init GLFW.");
        return -1;
    }

    glfwSetErrorCallback(errorcb);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
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


#line 1 "Elixir.Uderzo.Bindings"// Generated code for draw_eyes do not edit!
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
    GLFWwindow * window;
    assert(ei_decode_longlong(buf, index, (long long *) &window) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    nvgEndFrame(vg);
    glEnable(GL_DEPTH_TEST);
    glfwSwapBuffers(window);
    glfwPollEvents();
    char response[BUF_SIZE];
    int response_index = 0;
    ei_encode_version(response, &response_index);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_pid(response, &response_index, &pid);
    ei_encode_atom(response, &response_index, "uderzo_end_frame_done");
    write_response_bytes(response, response_index);
}

// Generated code for uderzo_start_frame do not edit!
static void _dispatch_uderzo_start_frame(const char *buf, unsigned short len, int *index) {
    int fbHeight;
    int fbWidth;
    double mouse_x;
    double mouse_y;
    erlang_pid pid;
    double pxRatio;
    double t;
    int winHeight;
    int winWidth;
    double win_height;
    double win_width;
    GLFWwindow * window;
    assert(ei_decode_longlong(buf, index, (long long *) &window) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    glfwGetCursorPos(window, &mouse_x, &mouse_y);
    glfwGetWindowSize(window, &winWidth, &winHeight);
    glfwGetFramebufferSize(window, &fbWidth, &fbHeight);
    pxRatio = fbWidth / winWidth;
    glViewport(0, 0, fbWidth, fbHeight);
    glClearColor(0.3, 0.3, 0.32, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    nvgBeginFrame(vg, winWidth, winHeight, pxRatio);
    win_width = winWidth;    win_height = winHeight;    char response[BUF_SIZE];
    int response_index = 0;
    ei_encode_version(response, &response_index);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_pid(response, &response_index, &pid);
    ei_encode_tuple_header(response, &response_index, 5);
    ei_encode_atom(response, &response_index, "uderzo_start_frame_result");
    ei_encode_double(response, &response_index, mouse_x);
    ei_encode_double(response, &response_index, mouse_y);
    ei_encode_double(response, &response_index, win_width);
    ei_encode_double(response, &response_index, win_height);
    write_response_bytes(response, response_index);
}

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
        vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
        assert(vg != NULL);
        loadDemoData(vg, &data);
    }
    if (window != NULL) {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_atom(response, &response_index, "glfw_create_window_result");
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
        ei_encode_string(response, &response_index, "Could not create window");
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
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--576460752303423487.gperf  */
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
#error "gperf generated tables don't work with this execution character set. Please report a bug to <bug-gperf@gnu.org>."
#endif

#line 1 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
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
hash (register const char *str, register size_t len)
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

struct dispatch_entry *
in_word_set (register const char *str, register size_t len)
{
  static struct dispatch_entry wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""},
#line 12 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"comment", _dispatch_comment},
      {""},
#line 6 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"draw_eyes", _dispatch_draw_eyes},
      {""},
#line 7 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"demo_render", _dispatch_demo_render},
      {""}, {""}, {""}, {""},
#line 8 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"uderzo_end_frame", _dispatch_uderzo_end_frame},
      {""},
#line 9 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"uderzo_start_frame", _dispatch_uderzo_start_frame},
      {""}, {""}, {""}, {""},
#line 11 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
      {"glfw_create_window", _dispatch_glfw_create_window},
#line 10 "/tmp/clixir-temp-nonode@nohost--576460752303423487.gperf"
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

