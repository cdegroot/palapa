defmodule MajordomoVault.Server do
  use GenServer

  ## Client of this GenServer in the API module, MajordomoVault.

  def start_link(_arg, opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  ## Server side stuff

  def init([]) do
    {:ok, _data} = MajordomoVault.File.decrypt_and_read()
  end

  def handle_call({:get, path}, _from, data) do
    result = Map.get(data, path)
    {:reply, result, data}
  end

  def handle_call({:put, path, value}, _from, data) do
    new_data = Map.put(data, path, value)
    :ok = MajordomoVault.File.encrypt_and_write(new_data)
    {:reply, :ok, new_data}
  end

end
