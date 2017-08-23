#! /usr/bin/env python
# -*- coding: utf-8 -*-

from threading import *
import binascii

import Constants
import LogManager

import CostiFPGA

# Global nickname for the logmanager
log = LogManager.Instance()
fpga = CostiFPGA.Instance()

class DataAcquireThread(Thread):
  
  def __init__(self):
    Thread.__init__(self)
    self.closeEventHandle = Event()

  def run(self):
    while not self.closeEventHandle.wait(Constants.ADC_DATA_CHECK_INTERVAL):
      fpga.updateTriggerOuts()
      if fpga.isTriggered(Constants.OK_BIT_SDRAM_READY):
        data = fpga.getADCData()
        print binascii.hexlify(data.toByteArray()[0:15])
      else :
        pass

  def stop(self):
    self.closeEventHandle.set()
