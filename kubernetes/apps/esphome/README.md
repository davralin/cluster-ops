docker run --rm --privileged -v "${PWD}":/config --device=/dev/ttyUSB0 -it --entrypoint /bin/bash ghcr.io/esphome/esphome
esptool.py --port /dev/ttyUSB0 write_flash 0x0 lol.bin