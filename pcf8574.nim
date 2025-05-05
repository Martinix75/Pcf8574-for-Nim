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

#import picostdlib/[stdio, gpio, i2c, time]
import picostdlib
import picostdlib/pico/[stdio, time]
import picostdlib/hardware/[gpio, i2c]

from math import log2

const 
  pcf8574Ver* = "2.0.0" #addattamenta a picostdlib >= 0.4.0 e via ref (era piu lento).
  p0*: byte = 0x01 #create a bit mask 
  p1*: byte = p0 shl 1
  p2*: byte = p0 shl 2
  p3*: byte = p0 shl 3
  p4*: byte = p0 shl 4
  p5*: byte = p0 shl 5
  p6*: byte = p0 shl 6
  p7*: byte = p0 shl 7

type 
  Pcf8574* = object #creates the pcf8574 object
    expAdd: uint8
    blockk: ptr I2cInst
    data: byte

proc writeByte*(self: var Pcf8574; data: byte; inverse: bool=true) = #proc to write the byte
  if inverse == true:
    self.data = not data
  else:
    self.data = data
  let addrData = self.data.unsafeAddr #get the address of the data
  discard writeBlocking(self.blockk, self.expAdd.I2cAddress, addrData, 1, false) #write the data on the i2c bus 

proc writeBit*(self: var Pcf8574, pin: uint8, value: bool) =
  if value == on:
    self.data = not self.data or pin #go to act (turn on) the selected bit 
    self.writeByte(self.data)
  elif value == off:
    let ctrl = not self.data shr uint8(log2(float(pin))) #Calculate if it is odd (moving the bit chosen to position 0) 
    if (ctrl mod 2) != 0: #if it is odd then bit = 1 and goes off 
      self.data = (self.data xor pin) #go to act (turn off) the selected bit 
      self.writeByte(self.data)

proc readByte*(self: var Pcf8574): byte =
  self.data = 0
  let addrByte = self.data.unsafeAddr
  discard readBlocking(self.blockk, self.expAdd.I2cAddress, addrByte, 1, false)
  result = self.data

proc readBit*(self: var Pcf8574; pin: uint8): bool =
  let bitValue: byte = self.readByte()
  result = bool(bitValue and pin)

proc setLow*(self: var Pcf8574) = #set data 0x00 all 0
  self.data = 0x00
  self.writeByte(self.data)

proc setHigh*(self: var Pcf8574) = #set data 0xff all 1
  self.data = 0xff
  self.writeByte(self.data)

proc newExpander*(blokk: ptr I2cInst; expAdd: uint8=0x20): Pcf8574 =
  result = Pcf8574(blockk: blokk, expAdd: expAdd)

when isMainModule:
  stdioInitAll()
  var exp = newExpander(blokk = i2c1, expAdd = 0x20)
  const sda = 2.Gpio 
  const scl = 3.Gpio 
  discard init(i2c1,10000)
  sda.setFunction(I2C); sda.pullUp()
  scl.setFunction(I2C); scl.pullUp()

  let timeSl: uint32 = 200
  var superCar: uint8 = 0x01
  while true:
    for _ in countup(0,6):
      exp.writeByte(superCar)
      superCar = superCar shl 1
      sleepMs(timeSl)
    for _ in countup(0,6):
      exp.writeByte(superCar)
      superCar = superCar shr 1
      sleepMs(timeSl)

