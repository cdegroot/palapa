defmodule Erix.Server.Leader do
  @moduledoc """
  Server state behaviour
  """
  require Logger
  use Erix.Constants

  @behaviour Erix.Server

  def transition_from(_, state) do
    %{state | state: :leader}
  end
end
