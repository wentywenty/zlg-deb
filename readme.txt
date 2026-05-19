ZHIYUAN USBCANFD200/400U Driver (DKMS)
=======================================

Driver version: 2.10
Kernel module:  usbcanfd
USB IDs:        04cc:1240 (USBCANFD-200U)
                3068:0009 (USBCANFD-400U)
CAN ports:      4
LIN ports:      2


Requirements
------------
- Linux kernel >= 4.x with SocketCAN support
- dkms, build-essential, linux-headers-$(uname -r)


Installation
------------

From pre-built .deb (recommended):

    sudo dpkg -i usbcanfd-dkms_2.10_all.deb
    # If headers are missing, install them first:
    sudo apt install linux-headers-$(uname -r)
    sudo dpkg -i usbcanfd-dkms_2.10_all.deb

From source (build .deb locally):

    sudo apt install dkms build-essential linux-headers-$(uname -r)
    make deb
    sudo dpkg -i usbcanfd-dkms_2.10_all.deb

Manual module build (no DKMS):

    sudo apt install build-essential linux-headers-$(uname -r)
    make all
    sudo insmod usbcanfd.ko


Verify Hardware Enumeration
---------------------------
    lsusb | grep -E '04cc:1240|3068:0009'

If the device is not detected, check USB cable and power.


Check CAN/LIN Network Interfaces
---------------------------------
    ls /sys/class/net | grep can
    ls /sys/class/net | grep lin

Expected: can0, can1, can2, can3, lin0, lin1


Channel Configuration
---------------------

Set bitrate and bring up CANFD interfaces:

    sudo ip link set can0 type can fd on \
        bitrate 500000 dbitrate 2000000 \
        sample-point 0.8 dsample-point 0.8
    sudo ip link set can0 up
    sudo ip link set can1 up

View channel settings:

    ip -details link show can0

All available options:

    ip link set can0 up type can help


LIN Channel Configuration
-------------------------
Set LIN0 as master:

    sudo sh -c 'echo {"LIN0":{"Enable":1,"IsMaster":1,"Baudrate":19200,"Feature":1,"TrEnable":1,"DataLen":8}} > /sys/bus/usb/drivers/usbcanfd/*/lin0_cfg'

Set LIN1 as slave:

    sudo sh -c 'echo {"LIN1":{"Enable":1,"IsMaster":0,"Baudrate":19200,"Feature":1,"TrEnable":0,"DataLen":8}} > /sys/bus/usb/drivers/usbcanfd/*/lin1_cfg'

Bring up LIN interfaces:

    sudo ip link set lin0 up type can fd on bitrate 1000000 dbitrate 1000000
    sudo ip link set lin1 up type can fd on bitrate 1000000 dbitrate 1000000


Sending Messages
----------------

CAN standard frame (8 bytes):

    cansend can0 123#11.22.33.44.55.66.77.88

CAN extended frame (29-bit ID):

    cansend can0 00000123#11.22.33.44.55.66.77.88

CANFD frame (12 bytes, use ##2 and pad to 12):

    cansend can0 123##2.00.11.22.33.44.55.66.77.88.00.00.00.00

CANFD accelerated frame (##3):

    cansend can0 123##3.00.11.22.33.44.55.66.77.88.00.00.00.00

LIN frame:

    cansend lin0 b12#00.11.22.33.44.55.66.77


Receiving Messages
------------------

All channels:

    candump any

Single channel:

    candump can0

With error frames:

    candump -e any,0:0,#FFFFFFFF

With timestamps:

    candump -tA any


Unloading the Driver
--------------------
    sudo rmmod usbcanfd

To also remove the DKMS registration:

    sudo dkms remove -m usbcanfd -v 2.10 --all


Receive Buffer Tuning
---------------------
If candump shows dropped frames but ifconfig counters don't,
increase the SocketCAN receive buffer:

    sudo sysctl -w net.core.rmem_max=26214400
    sudo sysctl -w net.core.rmem_default=26214400

To make permanent, add to /etc/sysctl.d/90-usbcanfd.conf:

    net.core.rmem_max = 26214400
    net.core.rmem_default = 26214400
