# Serial Wire Debug (SWD) host adapter

This implements serial wire debug as used on ARM microcontrollers.

## Signals
 - clock: free running system clock
 - swdio and swclk: the SWD pins
 - creset: an optional output
 - wvalid: write valid, assert with valid wdata
 - wdata: write data
 - rdata: read data, valid after a transaction is complete
 - status[0]: high when busy with a transaction
 - status[3:1]: SWD ack value, 1 = OK, 2 = wait, 4 = error, others reserved

## Commands

### Set creset command

 - wdata[36:32] = 0x13
 - wdata[0] = creset pin value to set

### Set swclk frequency command

 - wdata[36:32] = 0x12
 - wdata[7:0] = clkdiv

Sets the swclk frequency, fswclk = fclock / (2*(clkdiv + 1))

### Write 32 bits command
 - wdata[36:32] = 0x10
 - wdata[31:0] = data to transmit

Data is transmitted LSB first. Used for resetting and synchronizing
the SWD port. Write the sequence 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFE73C,
0xFFFFFFFF, 0x0000FFFF to initialize.

### SWD transaction command
 - wdata[36] = 0
 - wdata[35:34] = A[3:2] from SWD protocol
 - wdata[33] = 1 for read, 0 for write
 - wdata[32] = 1 for AP registers, 0 for DP registers
 - wdata[31:0] = data for write command, ignored for read

## Performance

An EFM32HG309 as well as an STM32F030 both worked properly at 31.25
MHz swclk. At this speed, both frequently ACK "wait". At 12.5 MHz, the
STM32 (48 MHz clock) always ACKs "OK", about 10 MHz for the EFM32.
