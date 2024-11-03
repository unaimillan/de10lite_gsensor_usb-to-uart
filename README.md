# DE10-Lite Gravity Sensor to PC over USB-to-UART converter

The project uses the Terasic DE10-Lite board to retrieve information from built-in accelerometer (3D gravity sensor) and send it to the Host PC using the CH430G serial converter.

## Setup

To clone the project use the following command:
```bash
git clone --recurse-submodules -j8 https://github.com/unaimillan/de10lite_gsensor_usb-to-uart.git
```

## Run

Run the project either using the Quartus Prime Lite GUI or the following command from the terminal:

```bash
quartus_sh.exe --flow compile ./usb-to-uart-pc-communication.qpf && quartus_pgm.exe --no_banner -c 1 --mode=jtag -o "P;output_files/usb-to-uart-pc-communication.sof"
```

Install the following VS Code extension for convenient Graph plotting [Teleplot](https://marketplace.visualstudio.com/items?itemName=alexnesnes.teleplot)

and run python script to collect data from COM port on Windows or TTY on Linux: `python .\serial-monitor.py`
