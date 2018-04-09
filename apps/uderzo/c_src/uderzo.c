
#include <stdio.h>
#define GLFW_INCLUDE_ES3
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include "nanovg.h"
// OpenGL ES 3 should support the widest array of devices
#define NANOVG_GLES3_IMPLEMENTATION
#include "nanovg_gl.h"
#include "nanovg_gl_utils.h"

#include <erl_interface.h>

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

int main() {
  char buffer[MAXATOMLEN];
  int index = 0;

  if (!glfwInit()) {
		printf("Failed to init GLFW.");
		return -1;
	}

  memset(buffer, 0, MAXATOMLEN);
  ei_encode_atom(buffer, &index, "test");
  printf("encoded shit to %s\n", buffer);

  puts("Hello, world");
}
