defmodule Uderzo.Clixir do
  @moduledoc """
  Code to emit Elixir and C code from a single "clixir" (.cx)
  file.
  """

  defmacro defgfx(clause, do: expression) do
    {function_name, _, parameter_ast} = clause
    parameter_list = Enum.map(parameter_ast, fn({p, _, _}) -> p end)
    {_block, _, exprs} = expression
    IO.puts("defgfx function_name = #{inspect function_name}")
    IO.puts("defgfx parameter_list = #{inspect parameter_list}")
    IO.puts("defgfx exprs = #{inspect exprs}")
    #c_code = make_c(function_name, parameter_list, exprs)
    # TODO do something with the c code
    # Stash in attributes, etcetera,
    #make_e(function_name, parameter_list, exprs)
  end

  # C code stuff starts here

  def make_c(function_name, parameter_list, exprs) do
    {:ok, iobuf} = StringIO.open("// Generated code for #{function_name} do not edit!")
    cdecls = cdecls(exprs)
    non_decls = non_decls(exprs)
    start_c_fun(iobuf, function_name)
    emit_c_local_vars(iobuf, cdecls)
    emit_c_unmarshalling(iobuf, parameter_list, cdecls)
    emit_c_body(iobuf, cdecls, non_decls)
    end_c_fun(iobuf)
    StringIO.contents(iobuf)
  end
  defp cdecls(exprs) do
    # Return c declarations as %{name -> type} map
    exprs
    |> Enum.flat_map(fn
      {:cdecl, _, [[{ctype, {cname, _, _}}]]} ->
        [{cname, ctype}]
      {:cdecl, _, [[{ctype, cnames}]]} ->
        Enum.map(cnames, fn({cname, _, _}) -> {cname, ctype} end)
      _ -> []
    end)
    |> Enum.filter(fn e -> !is_nil(e) end)
    |> Map.new
  end
  defp non_decls(exprs) do
    exprs
    |> Enum.filter(fn maybe_decl -> elem(maybe_decl, 0) != :cdecl end)
  end
  defp start_c_fun(iobuf, function_name) do
    IO.puts(iobuf, "static void _dispatch_#{function_name}(const char *buf, unsigned short len, int *index) {")
  end
  defp emit_c_local_vars(iobuf, cdecls) do
    cdecls
    |> Enum.map(fn
      ({decl, "char *"}) -> IO.puts(iobuf, "    char #{decl}[BUF_SIZE];")
                            IO.puts(iobuf, "    long #{decl};")
      ({decl, type}) ->     IO.puts(iobuf, "    #{to_string type} #{decl};")
    end)
  end
  defp emit_c_unmarshalling(iobuf, parameter_list, cdecls) do
    parameter_list
    |> Enum.map(fn(p) -> {p, cdecls[p]} end)
    |> Enum.map(fn
      # Fairly manual list, we can clean this up later when we have a better overview of regularities
      {name, :double} ->     "    assert(ei_decode_double(buf, index, &#{name}) == 0);"
      {name, :long} ->       "    assert(ei_decode_long(buf, index, &#{name}) == 0);"
      {name, "char *"} ->    "    assert(ei_decode_binary(buf, index, #{name}, #{name}_len) == 0);"
      {name, :erlang_pid} -> "    assert(ei_decode_pid(buf, index, &#{name}) == 0);"
      {name, type} ->
        if String.ends_with?(to_string(type), "*") do
                             "    assert(ei_decode_longlong(buf, index, &#{name}) == 0);"
        else
          raise "unknown type #{type} for variable #{name}, please fix macro"
        end
    end)
    |> Enum.map(&(IO.puts(iobuf, &1)))
  end
  # Ok, the following couple of functions are currently horribly named. Also, this
  # is not really clean - got incrementally built when working on Clixir's spec and
  # first implementation.
  # What really needs to happen is: TODO:
  # a) transform Elixir AST in C AST
  # b) emit C code for C AST
  @indent "    "
  defp emit_c_body(iobuf, cdecls, exprs, indent \\ @indent)
  defp emit_c_body(iobuf, cdecls, {:__block__, _, exprs}, indent) do
    emit_c_body(iobuf, cdecls, exprs, indent)
  end
  defp emit_c_body(iobuf, cdecls, exprs, indent) when is_list(exprs) do
    Enum.map(exprs, &(emit_c_body(iobuf, cdecls, &1, indent)))
  end
  defp emit_c_body(iobuf, cdecls, expr, indent) do
    case expr do
      {:=, _, [{left, _, _}, right]} ->
        # Assignment
        IO.write(iobuf, "#{indent}#{left} = ")
        emit_c_body(iobuf, cdecls, [right], "")
      {:if, _, if_stmt} ->
        emit_c_if(iobuf, cdecls, if_stmt, indent)
      {funcall, _, args} ->
        # Function call
        cargs = args
        |> Enum.map(&to_c_var/1)
        |> Enum.join(", ")
        IO.puts(iobuf, "#{indent}#{funcall}(#{cargs});")
      # Return tuple. This is probably more hardcoded than we need. Better safe than sorry
      # We _always_ return {pid, {return_tuple}}
      {{:pid, _, _}, return_values} ->
        retvals = return_values
        |> Tuple.to_list
        |> Enum.map(fn
          {name, _, _} -> name
          atom         -> {:atom, atom}
        end)
        emit_marshal_return_values(iobuf, retvals, cdecls, indent)
      expr -> raise "unknown expr #{inspect expr}, please fix macro or defgfx declaration"
    end
  end
  def to_c_var(expr) do
    case expr do
      {name, _, nil} -> to_string(name)
      {name, _, context} when is_atom(context) -> to_string(name)
      {:&, _, [{name, _, nil}]} -> "&" <> to_string(name)
      {:__aliases__, _, [name]} -> to_string(name)
      {oper, _, [lhs, rhs]} -> "#{to_c_var(lhs)} #{to_string(oper)} #{to_c_var(rhs)}"
      other_pattern -> raise "unknown C AST form #{inspect other_pattern}, please fix macro"
    end
  end
  # For now, only single-operator if statements are handled.
  defp emit_c_if(iobuf, cdecls, [conditional, [do: if_true_exprs]], indent) do
    IO.puts(iobuf, "#{indent}if (#{to_c_var(conditional)}) {")
    emit_c_body(iobuf, cdecls, if_true_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}}")
  end
  defp emit_c_if(iobuf, cdecls, [conditional, [do: if_true_exprs, else: if_false_exprs]], indent) do
    IO.puts(iobuf, "#{indent}if (#{to_c_var(conditional)}) {")
    emit_c_body(iobuf, cdecls, if_true_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}} else {")
    emit_c_body(iobuf, cdecls, if_false_exprs, indent <> @indent)
    IO.puts(iobuf, "#{indent}}")
  end
  defp emit_marshal_return_values(iobuf, retvals, cdecls, indent) do
    IO.puts(iobuf, """
      #{indent}char response[BUF_SIZE];
      #{indent}int response_index = 0;
      #{indent}ei_encode_version(response, &response_index);
      #{indent}ei_encode_tuple_header(response, &response_index, 2);
      #{indent}ei_encode_pid(response, &response_index, &pid);
      #{indent}ei_encode_tuple_header(response, &response_index, #{length(retvals)});
      """)
    retvals
    |> Enum.map(fn(retval) ->
      type = cdecls[retval]
      case {retval, type} do
        {{:atom, atom}, nil} ->
          IO.puts(iobuf, "#{indent}ei_encode_atom(response, &resonse_index, #{to_string atom});")
        {name, :double} ->
          IO.puts(iobuf, "#{indent}ei_encode_double(response, &response_index, #{name});")
        {name, type} ->
          if String.ends_with?(to_string(type), "*") do
            IO.puts(iobuf, "#{indent}ei_encode_longlong(response, &response_index, (long long) #{name});")
          else
            raise("unknown type in return #{inspect name}: #{inspect type}, please fix macro")
          end
      end
    end)
    IO.puts(iobuf, "#{indent}write_response_bytes(response, response_index);")
  end
  defp end_c_fun(iobuf) do
    IO.puts(iobuf, "}")
  end

  # Elixir code stuff starts here

  def make_e(function_name, parameter_list, _exprs) do
    quote do
      def unquote(function_name)(unquote_splicing(parameter_list)) do
        GraphicsServer.send_command(GraphicsServer, {unquote(function_name), unquote_splicing(parameter_list)})
      end
    end
  end
end
