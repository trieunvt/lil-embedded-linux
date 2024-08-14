# Pin Number Calculator

This little embedded system project calculates ROC-RK3328-CC GPIO pin number for interacting via the Linux `sysfs` file system at `/sys/class/gpio/gpio[pin_number]`.

## Execute

```sh
USAGE: sh PinNumCalc.sh [bank_number] [pad_name] [pad_number]
E.G.:
    Input:      sh PinNumCalc.sh 2 A 6
    Output:     GPIO2-A6 pin number = 70
                -> /sys/class/gpio/gpio70
```
