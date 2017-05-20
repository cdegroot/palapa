defmodule Erix do
  @moduledoc """
  Documentation for Erix.
  """

  @doc """
  Generate a unique ID.

  This function is used in several places throughout source and test code of Erix.
  Rather than splattering the code with uuid calls, we funnel them through here
  so we can easily swap it out if we want to.
  """
  defdelegate unique_id, to: Simpler.UniqueId, as: :unique_id_string
end
