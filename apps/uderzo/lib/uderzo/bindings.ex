defmodule Uderzo.Bindings do
  use Uderzo.Clixir

  @clixir_target "c_src/uderzo"

  defgfx comment(comment) do
    cdecl "char *": comment
    fprintf(stderr, "Got comment [%s]\n", comment)
  end

  defgfx glfw_create_window(width, height, title, pid) do
    cdecl "char *": title
    cdecl long: [length, width, height]
    cdecl erlang_pid: pid
    cdecl "GLFWWindow *": window
    window = glfwCreateWindow(width, height, title, NULL, NULL)
    glfwMakeContextCurrent(window)
    if vg == NULL do
      vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
      assert(vg != NULL)
    end
    if window != NULL do
      {pid, {:ok, window}}
    else
      # TODO this is sent as an atom instead of a binary.
      {pid, {:error, "Could not create window"}}
    end
  end

  defgfx glfw_destroy_window(window) do
    cdecl "GLFWWindow *": window
    glfwDestroyWindow(window)
  end
end
