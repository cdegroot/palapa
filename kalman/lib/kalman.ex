defmodule Kalman do
  @moduledoc """
  Documentation for Kalman.
  """

  defstruct [:a,  # Process dynamics
             :b,  # Control dynamics
             :c,  # Measurement dynamics
             :x,  # Current state estimate
             :p,  # Current probability of state estimate
             :q,  # Process covariance
             :r]  # Measurement covariance

  def new(keywords \\ []) when is_list(keywords) do
    state = make_default()
    Enum.reduce(keywords, state, fn {k, v}, state -> Map.replace!(state, k, v) end)
  end

  def make_default(a \\ 1.0, b \\ 0.0, c \\ 1.0, x \\ 10.0, p \\ 1.0, q \\ 0.005, r \\ 1.0) do
    %__MODULE__{a: a, b: b, c: c, x: x, p: p, q: q, r: r}
  end

  def step(control_input, measurement, state = %__MODULE__{}) do
    # Prediction step
    predicted_state_estimate = state.a * state.x + state.b * control_input
    predicted_prob_estimate = (state.a * state.p) * state.a + state.q

    # Observation step
    innovation = measurement - state.c * predicted_state_estimate
    innovation_covariance = state.c * predicted_prob_estimate * state.c + state.r

    # Update step
    kalman_gain = predicted_prob_estimate * state.c * 1 / innovation_covariance
    new_x = predicted_state_estimate + kalman_gain * innovation

    # eye(n) = nxn identity matrix.
    new_p = (1 - kalman_gain * state.c) * predicted_prob_estimate

    %__MODULE__{state | x: new_x, p: new_p}
  end

  def estimate(%__MODULE__{x: x}), do: x
end
