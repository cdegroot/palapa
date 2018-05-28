use Mix.Config

config :controller,
  indoor_sensor_mod: FakeTemperatureSensor,
  outdoor_sensor_mod: FakeTemperatureSensor,
  heating_controller: FakeHeatingController
