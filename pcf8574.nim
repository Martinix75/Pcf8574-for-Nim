#[
Driver for 8bit expander Pcf8574 write in Nim.
The MIT License (MIT)
Copyright (c) 2022 Martin Andrea (Martinix75)
testet with Nim 1.6.6

author Andrea Martin (Martinix75)
https://github.com/Martinix75/Raspberry_Pico/tree/main/Libs/pcf8574
]#

## Module to manage the PCF8574.
## Allows you to read and write either individual bits, or whole bytes.

import picostdlib/[stdio, gpio, i2c, time]

from math import log2

const 
  pcf8574Ver* = "1.4.0"
  p0*: byte = 0x01 #create a bit mask 
  p1*: byte = p0 shl 1
  p2*: byte = p0 shl 2
  p3*: byte = p0 shl 3
  p4*: byte = p0 shl 4
  p5*: byte = p0 shl 5
  p6*: byte = p0 shl 6
  p7*: byte = p0 shl 7

type 
  Pcf8574* = ref object #creates the pcf8574 object
    expAdd: uint8
    blockk: I2cInst
    data: byte

proc writeByte*(self: Pcf8574; data: byte; inverse: bool=true) = #proc to write the byte
  ## Write a whole byte (8bit) on the PCF8574 register.
  ##
  runnableExamples:
    self.writeByte(0xFF)
  ## ** Parameters**
  ## - *data:* it is the byte you want to write on the pcf8574 register.
  ## - *inverse:* Normally the byte is reversed, because the pcf8574 works with reverse logic.
  if inverse == true:
    self.data = not data
  else:
    self.data = data
  let addrData = self.data.unsafeAddr #get the address of the data
  writeBlocking(self.blockk, self.expAdd, addrData, 1, false) #write the data on the i2c bus 

proc writeBit*(self: Pcf8574, pin: uint8, value: bool) =
  ## Write a single bit on pcf8574 on the exit desired (p0, p1..p7).
  ##
  runnableExamples:
    self.writeBit(pin=p3, value=on)
  ## **Parameters**
  ## - *pin:* it is the pin on which you want to write the new value (p0..p7).
  ## - *value:* *on* = set exit high, *off* = set exit low.
  if value == on:
    self.data = not self.data or pin #go to act (turn on) the selected bit 
    self.writeByte(self.data)
  elif value == off:
    let ctrl = not self.data shr uint8(log2(float(pin))) #Calculate if it is odd (moving the bit chosen to position 0) 
    if (ctrl mod 2) != 0: #if it is odd then bit = 1 and goes off 
      self.data = (self.data xor pin) #go to act (turn off) the selected bit 
      self.writeByte(self.data)

proc readByte*(self: Pcf8574): byte =
  ## Read the entry byte present that istant on pcf8574 (8bit).
  ##
  runnableExamples:
    let pfcByte = self.readByte()
    print("Byte on pcf8574: " & $pcfByte & '\n')
  ## **return**
  ## - *Byte*
  self.data = 0
  let addrByte = self.data.unsafeAddr
  discard readBlocking(self.blockk, self.expAdd, addrByte, 1, false)
  result = self.data

proc readBit*(self: Pcf8574; pin: uint8): bool =
  ## Read the value of a single bit in the pcf8574 register.
  ##
  runnableExamples:
    var valuP2 = self.readBit(p2)
  ## **parameters**
  ## - *pin:* it is the pin on which you want to read (p0..p7).
  ## **return**
  ## - *bool* *on* if the value is high, *off* if the value is low.
  let bitValue: byte = self.readByte()
  result = bool(bitValue and pin)

proc setLow*(self: Pcf8574) = #set data 0x00 all 0
  ## Set all low.
  ##
  runnableExamples:
    self.stLow()
  self.data = 0x00
  self.writeByte(self.data)

proc setHigh*(self: Pcf8574) = #set data 0xff all 1
  ## set all high.
  ##
  runnableExamples:
    self.setHigh()
  self.data = 0xff
  self.writeByte(self.data)

proc newExpander*(blokk: I2cInst; expAdd: uint8=0x20): Pcf8574 =
  result = Pcf8574(blockk: blokk, expAdd: expAdd)

