# TimTempSensor

Temperature Sensor for TIM.

All I had was an NTC thermistor and an ATtiny45. I hook one up to the other, make
ATtiny45 be the A/D converter that the RPi3 lacks.

TODO:

* [ ] ATtiny45 firmware
* [ ] Find free pins how there's an LCD HAT display
* [ ] Clixir driver to talk to the ATtiny45
* [ ] Calibration.

Pointers:

https://www.rototron.info/raspberry-pi-avr-programmer-spi-tutorial/ has the necessary
steps and code to make an ATtiny45 talk SPI. When that's done, we can try adding
the A/D code.
