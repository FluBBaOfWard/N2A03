# RP2A03 V0.0.9

RP2A03 (NES) CPU/sound chip emulator for ARM32.

## How to use

To connect devices to memory range 0x4020-5FFF use rp2A03MemRead & rp2A03MemWrite.
To connect devices to 4016/4017 D0-D7 use rp2A03IORead0 & rp2A03IORead1.
To connect devices to 4016 OUT0-OUT2 use rp2A03IOWrite.

## Projects That use this CPU/sound core

* https://github.com/FluBBaOfWard/NesDS
* https://github.com/FluBBaOfWard/PunchOutDS

## Credits

```text
Most code is derived from PocketNES which was started by Loopy.
Dwedit helped with a lot of things. https://www.dwedit.org
```
