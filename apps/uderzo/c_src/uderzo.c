
#include <stdio.h>
#define GLFW_INCLUDE_ES3
#define GLFW_INCLUDE_GLEXT
#include <GLFW/glfw3.h>
#include "nanovg.h"
// OpenGL ES 3 should support the widest array of devices
#define NANOVG_GLES3_IMPLEMENTATION
#include "nanovg_gl.h"
#include "nanovg_gl_utils.h"

int main() {
  if (!glfwInit()) {
		printf("Failed to init GLFW.");
		return -1;
	}

  puts("Hello, world");
}
