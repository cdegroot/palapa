# Tim

Thermostat, IMproved.

Or a backcronym around Mr. Home Improvement, [Tim Allen](https://www.google.ca/search?q=tim+allen&source=lnms&tbm=isch&sa=X&ved=0ahUKEwin2P760e7YAhVHzoMKHWAPCaIQ_AUICygC&biw=1154&bih=851). I decided not to put his face in this readme, just a link ;-).

## What? 

A thermostat, meant to double up as a Nerves-based home automation controller. At some time. 

## Why? 

I have a very modern two-stage high-efficiency furnace which the previous owner of my 
place put in, but he left the old thermostat with just two wires. This is not optimal,
and I had the choice of investing $$$ into closed-source stuff like Ecobee, or
look at a DIY option. A $1400 propane tank refill bill made saving some LPG
top of mind ;-)

## How?

Simple (at least, that's the plan):

* The two thermostat wires will be used to measure temperature, old-school using a 
  thermistor and an ATtiny45 for A/D converter;
* The ATtiny45 will talk I2C or SPI to a RPi3 to communicate indoor temperature;
* My existing outdoor sensor from Lacrosse will be read by the same RPi3 using 
  an RTL-SDR dongle I had gathering dust;
* Three 250VAC/10A solid state relays will switch the three controls of the furnace
  for first stage, second stage heat and the fan;
* Some control software in Elixir;
* A responsive UI in Phoenix. 

Given that I had everything in house, it's $10 parts just for the SSRs (I didn't have 
these and didn't want to risk something homebrew to drive a $$$$ furnace; the parts
should be fine, although I would never, ever, think of using them to actually switch
line voltages - the furnace uses 24VAC which should be fine though). I guess if you need
to buy an RPi3, the SSRs, the RTL-SDR dongle (outdoor temp optional of course) and a
1-wire temperature sensor (probably better than what I'm gonna use) you'd still land well 
south of $100 and have something way more powerful than an Ecobee. 

## But... 

Yes, Ecobee is full of people who specialize in control technology and they probably have
superiour algorithms. But - they need to be right ahead of time and be very general. All 
I need to do is tinker until my thermostat stops making the room temperature overshoot 
the set temp, which as far as I can tell is the largest waste. Also, more fun this way. And
I'll have something that eventually can also drive other stuff (I want to be able to remotely
control my water heater, lights, etcetera - the Pi sitting in the middle of some RF stuff
controlling a handful of Atmel microcontrollers should be more than capable). 

# Setup

Install stuff:

    sudo apt-get install cmake rtl-sdr librtlsdr0-dev

to get some handy tools and librtlsdr. We need to give user-level access to the dongle, mine
is 0bda:2838, use `lsusb` to find your vendor:device combo:

    echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="adm", MODE="0666", SYMLINK+="rtl_sdr"' | sudo tee /etc/udev/rules.d/20.rtlsdr.rules
    
Next, checkout, build and install rtl_433

    git@github.com:merbanan/rtl_433
    cd rtl_433
    mkdir build
    cd build
    cmake ../
    make && sudo make install

Note that this skips the testing - check rtl\_433's `do_build.sh` for details. Plugin the dongle and do
a quick test:

    rtl_433 -R 73

For my Lacrosse sensor; it should start reporting the temperature - make a note of the id, you'll need
it (now and every time you change batteries, alas). 

For the UI, node is needed

    asdf plugin-add nodejs
    bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    
To fetch the world:

    asdf install
