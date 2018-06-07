#include <clixir_support.h>
#line 1 "c_src/tim_uderzo_ui.hx"
// -*- mode; c; -*-

#include "uderzo_support.h"


// END OF HEADER


// Generated code for draw_button_with_arrow from Elixir.TimUderzoUi

#line 102 "/home/cees/mine/palapa/tim_uderzo_ui/lib/tim_uderzo_ui.ex"
static void _dispatch_Elixir_TimUderzoUi_draw_button_with_arrow(const char *buf, unsigned short len, int *index) {
    double h;
    long up;
    double w;
    double x;
    double y;
    assert(ei_decode_long(buf, index, &up) == 0);
    assert(ei_decode_double(buf, index, &x) == 0);
    assert(ei_decode_double(buf, index, &y) == 0);
    assert(ei_decode_double(buf, index, &w) == 0);
    assert(ei_decode_double(buf, index, &h) == 0);
    nvgBeginPath(vg);
    nvgRoundedRect(vg, x, y, w, h, w / 20.0);
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 128));
    nvgFill(vg);
    nvgStrokeColor(vg, nvgRGBA(128, 128, 128, 255));
    nvgStroke(vg);
    nvgBeginPath(vg);
    if (up == 1) {
        nvgMoveTo(vg, x + w * 0.1, y + h * 0.9);
        nvgLineTo(vg, x + w * 0.9, y + h * 0.9);
        nvgLineTo(vg, x + w * 0.5, y + h * 0.1);
        nvgFillColor(vg, nvgRGBA(200, 64, 64, 255));
    } else {
        nvgMoveTo(vg, x + w * 0.1, y + h * 0.1);
        nvgLineTo(vg, x + w * 0.9, y + h * 0.1);
        nvgLineTo(vg, x + w * 0.5, y + h * 0.9);
        nvgFillColor(vg, nvgRGBA(64, 64, 200, 255));
    }
    nvgFill(vg);
    nvgStrokeColor(vg, nvgRGBA(128, 128, 128, 255));
    nvgStroke(vg);
}

// Generated code for draw_text from Elixir.TimUderzoUi

#line 90 "/home/cees/mine/palapa/tim_uderzo_ui/lib/tim_uderzo_ui.ex"
static void _dispatch_Elixir_TimUderzoUi_draw_text(const char *buf, unsigned short len, int *index) {
    double sz;
    char t[BUF_SIZE];
    long t_len;
    long tl;
    double x;
    double y;
    assert(ei_decode_binary(buf, index, t, &t_len) == 0);
    t[t_len] = '\0';
    assert(ei_decode_long(buf, index, &tl) == 0);
    assert(ei_decode_double(buf, index, &sz) == 0);
    assert(ei_decode_double(buf, index, &x) == 0);
    assert(ei_decode_double(buf, index, &y) == 0);
    nvgFontSize(vg, sz);
    nvgFontFace(vg, "sans");
    nvgTextAlign(vg, NVG_ALIGN_LEFT | NVG_ALIGN_TOP);
    nvgFillColor(vg, nvgRGBA(255, 255, 255, 255));
    nvgText(vg, x, y, t, t + tl);
}

// Generated code for create_font from Elixir.TimUderzoUi

#line 15 "/home/cees/mine/palapa/tim_uderzo_ui/lib/tim_uderzo_ui.ex"
static void _dispatch_Elixir_TimUderzoUi_create_font(const char *buf, unsigned short len, int *index) {
    char file_name[BUF_SIZE];
    long file_name_len;
    char name[BUF_SIZE];
    long name_len;
    int retval;
    assert(ei_decode_binary(buf, index, name, &name_len) == 0);
    name[name_len] = '\0';
    assert(ei_decode_binary(buf, index, file_name, &file_name_len) == 0);
    file_name[file_name_len] = '\0';
    assert(nvgCreateFont(vg, name, file_name) >= 0);
}


#line 1 "c_src/uderzo.hx"
// -*- mode: c; -*-

/*
 * This is the Clixir "header" that is put on top of the generated
 * code. It should contain
 * a) includes needed for the generated code;
 * b) a main method
 * c) any other stuff you can think off ;-)
 */
#include "uderzo_support.h"

extern void errorcb(int error, const char *desc);
extern void read_loop();

// These pesky global things, for now.
NVGcontext* vg = NULL;
#ifdef UDERZO_VC
VC_STATE_T state;
#endif

int uderzo_init() {

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

   glClear(GL_COLOR_BUFFER_BIT);
   assert(glGetError() == 0);

   // Not in GLES2? TODO check glMatrixMode(GL_MODELVIEW);

   vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
   assert(vg != NULL);

   uderzo_vcfbcp_init(); // Ignore errors for now.
#else
    if (!glfwInit()) {
        fprintf(stderr, "Uderzo: Failed to init GLFW.");
        return -1;
    }

    glfwSetErrorCallback(errorcb);
    glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);

    fprintf(stderr, "Uderzo executable initialized.");
#endif
}

void errorcb(int error, const char *desc) {
    // TODO proper callback on stdout as well.
    fprintf(stderr, "GLFW error %d: %s\n", error, desc);
    // For now, just crash.
    assert(0);
}

#ifdef UDERZO_VC

// Code originally from https://github.com/tasanakorn/rpi-fbcp
// Note that faster/more complex variants exist (Adafruit has one
// that checks the minim rectangle to be copied), but for standard
// embedded displays low framerates shouldn't be bad. Feel free to
// disagree and send patches ;-)

// One-time initialization of the copying process. This opens files, sets
// up one-time variables, and basically readies us for the tight-loop (once
// per frame) stuff. Returns 0 on success, -1 on error.
int uderzo_vcfbcp_init() {
    struct fb_fix_screeninfo finfo;
    uint32_t image_prt;

    state.vcfbcp_fbfd = open("/dev/fb1", O_RDWR);
    if (state.vcfbcp_fbfd == -1) {
        fprintf(stderr, "Unable to open secondary display\n");
        return -1;
    }
    if (ioctl(state.vcfbcp_fbfd, FBIOGET_FSCREENINFO, &finfo)) {
        fprintf(stderr, "Unable to get secondary display information\n");
        return -1;
    }
    if (ioctl(state.vcfbcp_fbfd, FBIOGET_VSCREENINFO, &state.vcfbcp_vinfo)) {
        fprintf(stderr, "Unable to get secondary display information\n");
        return -1;
    }

    fprintf(stderr, "SPI Display screen size is %d by %d, bpp=%d\n", state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres, state.vcfbcp_vinfo.bits_per_pixel);

    state.vcfbcp_screen_resource = vc_dispmanx_resource_create(VC_IMAGE_RGB565, state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres, &image_prt);
    if (!state.vcfbcp_screen_resource) {
        fprintf(stderr, "Unable to create screen buffer\n");
        close(state.vcfbcp_fbfd);
        return -1;
    }

    state.vcfbcp_fbp = (char*) mmap(0, finfo.smem_len, PROT_READ | PROT_WRITE, MAP_SHARED,
                                    state.vcfbcp_fbfd, 0);
    if (state.vcfbcp_fbp <= 0) {
        fprintf(stderr, "Unable to create mamory mapping\n");
        close(state.vcfbcp_fbfd);
        vc_dispmanx_resource_delete(state.vcfbcp_screen_resource);
        return -1;
    }

    vc_dispmanx_rect_set(&state.vcfbcp_rect, 0, 0, state.vcfbcp_vinfo.xres, state.vcfbcp_vinfo.yres);

    state.vcfbcp_initialized = VCFBCP_INITIALIZED; // zee magic cookie
    return 0;
}

// Copies current frame to secondary display. Returns -1 on trouble.
int uderzo_vcfbcp_copy() {
    if (state.vcfbcp_initialized != VCFBCP_INITIALIZED) {
        fprintf(stderr, "VideoCore framebuffer copy not initialized, did you call uderzo_vcfbcp_init?\n");
        return -1;
    }

    vc_dispmanx_snapshot(state.dispman_display, state.vcfbcp_screen_resource, 0);
    vc_dispmanx_resource_read_data(state.vcfbcp_screen_resource, &state.vcfbcp_rect, state.vcfbcp_fbp,
                                   state.vcfbcp_vinfo.xres * state.vcfbcp_vinfo.bits_per_pixel / 8);
    return 0;
}

#endif // UDERZO_VC specific code

// End of manually maintained header. Generated code follows below.


// END OF HEADER


// Generated code for uderzo_end_frame from Elixir.Uderzo.Bindings

#line 196 "/home/cees/mine/uderzo_poncho/uderzo/lib/uderzo/bindings.ex"
static void _dispatch_Elixir_Uderzo_Bindings_uderzo_end_frame(const char *buf, unsigned short len, int *index) {
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

// Generated code for uderzo_start_frame from Elixir.Uderzo.Bindings

#line 152 "/home/cees/mine/uderzo_poncho/uderzo/lib/uderzo/bindings.ex"
static void _dispatch_Elixir_Uderzo_Bindings_uderzo_start_frame(const char *buf, unsigned short len, int *index) {
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

// Generated code for glfw_destroy_window from Elixir.Uderzo.Bindings

#line 129 "/home/cees/mine/uderzo_poncho/uderzo/lib/uderzo/bindings.ex"
static void _dispatch_Elixir_Uderzo_Bindings_glfw_destroy_window(const char *buf, unsigned short len, int *index) {
    GLFWwindow * window;
    assert(ei_decode_longlong(buf, index, (long long *) &window) == 0);
    glfwDestroyWindow(window);
}

// Generated code for glfw_create_window from Elixir.Uderzo.Bindings

#line 101 "/home/cees/mine/uderzo_poncho/uderzo/lib/uderzo/bindings.ex"
static void _dispatch_Elixir_Uderzo_Bindings_glfw_create_window(const char *buf, unsigned short len, int *index) {
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
    title[title_len] = '\0';
    assert(ei_decode_pid(buf, index, &pid) == 0);
    window = glfwCreateWindow(width, height, title, NULL, NULL);
    glfwMakeContextCurrent(window);
    glfwSwapInterval(0);
    if (vg == NULL) {
        vg = nvgCreateGLES2(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG);
        assert(vg != NULL);
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

// Generated code for uderzo_init from Elixir.Uderzo.Bindings

#line 18 "/home/cees/mine/uderzo_poncho/uderzo/lib/uderzo/bindings.ex"
static void _dispatch_Elixir_Uderzo_Bindings_uderzo_init(const char *buf, unsigned short len, int *index) {
    erlang_pid pid;
    assert(ei_decode_pid(buf, index, &pid) == 0);
    uderzo_init();
    char response[BUF_SIZE];
    int response_index = 0;
    ei_encode_version(response, &response_index);
    ei_encode_tuple_header(response, &response_index, 2);
    ei_encode_pid(response, &response_index, &pid);
    ei_encode_atom(response, &response_index, "uderzo_initialized");
    write_response_bytes(response, response_index);
}


/* ANSI-C code produced by gperf version 3.1 */
/* Command-line: /usr/bin/gperf -t /tmp/clixir-temp-nonode@nohost--576460752303314940.gperf  */
/* Computed positions: -k'24' */

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

#line 1 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
struct dispatch_entry {
  char *name;
  void (*dispatch_func)(const char *buf, unsigned short len, int *index);
};

#define TOTAL_KEYWORDS 8
#define MIN_WORD_LENGTH 28
#define MAX_WORD_LENGTH 42
#define MIN_HASH_VALUE 30
#define MAX_HASH_VALUE 51
/* maximum key range = 22, duplicates = 0 */

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
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 10, 52, 52, 52, 52,
      52, 52, 52,  5, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52,  0,  0, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52, 52, 52, 52, 52,
      52, 52, 52, 52, 52, 52
    };
  return len + asso_values[(unsigned char)str[23]];
}

struct dispatch_entry *
in_word_set (register const char *str, register size_t len)
{
  static struct dispatch_entry wordlist[] =
    {
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""}, {""},
      {""}, {""}, {""},
#line 8 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_TimUderzoUi_create_font", _dispatch_Elixir_TimUderzoUi_create_font},
      {""}, {""}, {""},
#line 13 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_Uderzo_Bindings_uderzo_init", _dispatch_Elixir_Uderzo_Bindings_uderzo_init},
      {""}, {""}, {""},
#line 7 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_TimUderzoUi_draw_text", _dispatch_Elixir_TimUderzoUi_draw_text},
#line 9 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_Uderzo_Bindings_uderzo_end_frame", _dispatch_Elixir_Uderzo_Bindings_uderzo_end_frame},
      {""},
#line 10 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_Uderzo_Bindings_uderzo_start_frame", _dispatch_Elixir_Uderzo_Bindings_uderzo_start_frame},
      {""}, {""}, {""}, {""},
#line 12 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_Uderzo_Bindings_glfw_create_window", _dispatch_Elixir_Uderzo_Bindings_glfw_create_window},
#line 11 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_Uderzo_Bindings_glfw_destroy_window", _dispatch_Elixir_Uderzo_Bindings_glfw_destroy_window},
      {""}, {""}, {""},
#line 6 "/tmp/clixir-temp-nonode@nohost--576460752303314940.gperf"
      {"Elixir_TimUderzoUi_draw_button_with_arrow", _dispatch_Elixir_TimUderzoUi_draw_button_with_arrow}
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

