// -*- mode: c; -*-

/*
 * This is the Clixir header that is put on top of the generated
 * code. It should contain
 * a) includes needed for the generated code;
 * b) a main method
 * c) any other stuff you can think off ;-)
 */

// OpenGL ES 2 should support the widest array of devices. 
// When UDERZO_VC is set, we target RaspberryPi's VideoCore.
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
