# TP-04 Disconnect/reset recovery

Every 10 s the firmware deletes the GT1151 driver and panel-I/O object,
resets the I2C master bus, recreates the touch device and reports recovery
time. It also continuously polls the controller and counts read errors.

The Korvo-1 BSP marks GT1151 reset and interrupt pins as NC, so this demo
focuses on I2C reset and driver reconnection. To exercise a physical LCD
sub-board unplug/replug, do it between two `RECOVERY` log lines and observe
`read_err`, `recover_err` and the next recovery latency. Repeat at least ten
cycles.
