# TimTempSensor

Temperature Sensor for TIM.

All I had was an NTC thermistor and a bunch of capacitors. Build an R/C circuit,
measure time to load the C, calculate R - at least, that's the idea.

```
pin 1  +--- VCC 3.3V
       |
       <
       >  NTC 10k/1% (a=1.475e-3, b=1.68e-4, c=4.3e-7)
       <
       |
pin 11 +--- GPIO (WiringPi pin 0)
       |
       -
       -  capacitor (electrolytic, 10µF)
       |
pin 6  +--- GND

```

Measuring is simple:
#. Put GPIO in output mode, set to low to drain capacitor.
#. Register interrupt handler on pin 0 leading edge.
#. Note the time.
#. Set GPIO to input mode.
#. Wait for interrupt to occur. The capacitor will charge until full,
   this slowly shifts the voltage drop from resistor to capacitor until
   there's enough voltage to make the GPIO read high.
#. Subtract interrupt time from start time.

The higher the temperature, the lower the resistance, the quicker the
capacitor charges. The 10µF was chosen to have measurements in the low
milliseconds. Given that the relationship between R/C and time is
linear, time and temp relate in the same way as resistance and temp and
therefore the Steinhart-Hart coefficients can be used with just a bit
of calibration.

TODO:

* [ ] Hookup hardware to lab pi
* [ ] Write wiringpi code
* [ ] Calibration
* [ ] Elixir interface
