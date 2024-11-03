import ctypes
import re
import socket
import time
import serial

# https://marketplace.visualstudio.com/items?itemName=alexnesnes.teleplot
teleplotAddr = ("127.0.0.1",47269)
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)


def sendTelemetry(name, value):
    now = time.time() * 1000
    msg = name+":"+str(now)+":"+str(value)+"|g"
    sock.sendto(msg.encode(), teleplotAddr)


def serial_readlines(port: serial.Serial):
    while port.readable():
        yield port.readline().decode()


def main():
    x_list = [0]
    y_list = [0]

    with serial.Serial('COM6', 115200, timeout=10) as s:
        for line in serial_readlines(s): # ["<FFB2|FFEC|014B>"]:
            if line.count('|') < 2:
                continue

            line = line.strip()
            print(line, end=' ')
            x, y, z = map(lambda x: ctypes.c_int16(int(x, base=16)).value, line.strip('<').strip('>').split('|'))
            avg_x = sum(x_list) / len(x_list)
            avg_y = sum(y_list) / len(y_list)

            if len(x_list) < 10 and abs(avg_x - x) < 200 and abs(avg_y - y) < 200:
                x_list.append(x)
                y_list.append(y)
            
            print(x, avg_x, y, avg_y)
            sendTelemetry('x', avg_x)
            sendTelemetry('y', avg_y)

            if len(x_list) >= 10:
                x_list.pop(0)
                y_list.pop(0)



if __name__ == '__main__':
    main()
