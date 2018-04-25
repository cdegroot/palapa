defmodule Uderzo.ClixirTest do
  use ExUnit.Case, async: true

  import Uderzo.Clixir

  # Example invocation. This should compile.
  defgfx glfw_get_cursor_pos(window, pid) do
    cdecl "GLFWwindow *": window
    cdecl erlang_pid: pid
    cdecl double: [mx, my]
    glfwGetCursorPos(window, &mx, &my)
    {pid, {mx, my}}
  end

  # Cleaned up stuff that the make_X methods receive
  @example_name :glfw_get_cursor_pos
  @example_params [:window, :pid]
  @example_expression [{:cdecl, [line: 8], [["GLFWwindow *": {:window, [line: 8], nil}]]}, {:cdecl, [line: 9], [[erlang_pid: {:pid, [line: 9], nil}]]}, {:cdecl, [line: 10], [[double: [{:mx, [line: 10], nil}, {:my, [line: 10], nil}]]]}, {:glfwGetCursorPos, [line: 11], [{:window, [line: 11], nil}, {:&, [line: 11], [{:mx, [line: 11], nil}]}, {:&, [line: 11], [{:my, [line: 11], nil}]}]}, {{:pid, [line: 12], nil}, {{:mx, [line: 12], nil}, {:my, [line: 12], nil}}}]

  # These two tests below suck and should die. But they should get us going ;-)

  test "correct Elixir code is generated" do
    # TODO: sync version, if we really want to
    expected = {:def, [context: Uderzo.Clixir, import: Kernel],
                [
                  {:glfw_get_cursor_pos, [context: Uderzo.Clixir], [:window, :pid]},
                  [
                    do: {{:., [],
                          [{:__aliases__, [alias: false], [:GraphicsServer]}, :send_command]}, [],
                         [
                           {:__aliases__, [alias: false], [:GraphicsServer]},
                           {:{}, [], [:glfw_get_cursor_pos, :window, :pid]}
                         ]}
                  ]
                ]}
    assert expected == make_e(@example_name, @example_params, @example_expression)
  end
  test "correct C code is generated" do
    expected = {"// Generated code for glfw_get_cursor_pos do not edit!",
 "static void _dispatch_glfw_get_cursor_pos(const char *buf, unsigned short len, int *index) {\n    double mx;\n    double my;\n    erlang_pid pid;\n    GLFWwindow * window;\n    assert(ei_decode_longlong(buf, index, &window) == 0);\n    assert(ei_decode_pid(buf, index, &pid) == 0);\n    glfwGetCursorPos(window, &mx, &my);\n    char response[BUF_SIZE];\n    int response_index = 0;\n    ei_encode_version(response, &response_index);\n    ei_encode_tuple_header(response, &response_index, 2);\n    ei_encode_pid(response, &response_index, &pid);\n    ei_encode_tuple_header(response, &response_index, 2);\n\n    ei_encode_double(response, &response_index, mx);\n    ei_encode_double(response, &response_index, my);\n    write_response_bytes(response, response_index);\n}\n"}
    assert expected == make_c(@example_name, @example_params, @example_expression)
  end

  test "embedded C code works" do
    ast = quote do
      cdecl "char *": title
      cdecl long: [length, width, height]
      cdecl erlang_pid: pid
      cdecl "GLFWWindow *": window
      window = glfwCreateWindow(width, height, title, NULL, NULL)
      if vg == NULL do
        vg = nvgCreateGLES3(NVG_ANTIALIAS | NVG_STENCIL_STROKES | NVG_DEBUG)
        assert(vg != NULL)
      end
      if window != NULL do
        {pid, {:ok, window}}
      else
        {pid, {:error, "Could not create window"}}
      end
    end
    {:__block__, _, exprs} = ast

    {hdr, c_string} = make_c(:glfw_create_window, [:width, :height, :title, :pid], exprs)

    assert hdr == "// Generated code for glfw_create_window do not edit!"
    assert c_string == """
static void _dispatch_glfw_create_window(const char *buf, unsigned short len, int *index) {
    long height;
    long length;
    erlang_pid pid;
    char * title;
    long width;
    GLFWWindow * window;
    assert(ei_decode_long(buf, index, &width) == 0);
    assert(ei_decode_long(buf, index, &height) == 0);
    assert(ei_decode_longlong(buf, index, &title) == 0);
    assert(ei_decode_pid(buf, index, &pid) == 0);
    window = glfwCreateWindow(width, height, title, NULL, NULL);
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

        ei_encode_atom(response, &resonse_index, ok);
        ei_encode_longlong(response, &response_index, (long long) window);
        write_response_bytes(response, response_index);
    } else {
        char response[BUF_SIZE];
        int response_index = 0;
        ei_encode_version(response, &response_index);
        ei_encode_tuple_header(response, &response_index, 2);
        ei_encode_pid(response, &response_index, &pid);
        ei_encode_tuple_header(response, &response_index, 2);

        ei_encode_atom(response, &resonse_index, error);
        ei_encode_atom(response, &resonse_index, Could not create window);
        write_response_bytes(response, response_index);
    }
}
"""
  end
end
