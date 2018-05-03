# Controller

This contains The Works - the actual thermostat code.

It can run in different modes depending on MIX_ENV:

* `dev` is regular development, and all the hardware is faked;
* `hw_dev` is hardware development, and assumes everything is there;
* `prod` is in production and of course assumes everything is there.

The actual modules are configured through the Mix config and disclosed
through the main controller module's helper functions. The controller
then contains the API to access:

* The indoor sensor, with history
* The outdoor sensor, with history
* The current state of the heating (fan off/on, stage off/one/two)
* The current set temperature (and, later on, schedule)
* Functions to override the set temperature and fan (run for five minutes, etc)
