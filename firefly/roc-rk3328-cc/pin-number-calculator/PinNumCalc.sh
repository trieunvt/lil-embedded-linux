#!/bin/sh

# Check for the correct number of arguments
if [ "$#" -ne "3" ]
then
    echo "USAGE: sh PinNumCalc.sh [bank_number] [pad_name] [pad_number]"
    echo "E.G.:"
    echo "    Input:      sh PinNumCalc.sh 2 A 6"
    echo "    Output:     GPIO2-A6 pin number = 70"
    echo "                -> /sys/class/gpio/gpio70"
    exit
fi

# Get input arguments
bank_number=$1
pad_name=$2
pad_number=$3

# Only accept pad names A-B-C-D (or a-b-c-d)
pad_name_value=`printf '%d' "'$pad_name"`

if [ "$pad_name_value" -ge "97" ]
then # Uppercase
    pad_name_value=`expr $pad_name_value - 97`
else # Lowercase
    pad_name_value=`expr $pad_name_value - 65`
fi

if [ "$pad_name_value" -ge "4" ]
then
    echo "Pad name not found!"
    exit
fi

# Calculate GPIO pin number
pin_number=`expr $bank_number \* 32 + $pad_name_value \* 8 + $pad_number`
echo "GPIO$bank_number-$pad_name$pad_number Pin Number = $pin_number"
echo "-> /sys/class/gpio/gpio$pin_number"
exit
