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
#ifndef UDERZO_VC
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
