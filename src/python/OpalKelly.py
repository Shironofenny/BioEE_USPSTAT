import imp
import sys
import os
import time

import FeUtils as utils

source_path = utils.feFindDir('lib',3)
if not source_path :
    # Exit the program when no library could found
    print('Library path not found, please check if library files exist')
    sys.exit(1)

source_path = source_path + '/ok/ok.py';

# Load library for Opal Kelly (ok)
ok = imp.load_source('ok', source_path)

# User defined modules
import LogManager

class OpalKelly(object):

  def __init__(self):
    self.xem = ok.okCFrontPanel()
    self.pll = ok.PLL22393()
    self.activationFlag = False

  def openDevice(self):
    errormsg = self.xem.OpenBySerial("")
    if (self.xem.NoError == errormsg):
        self.activationFlag = True
    return errormsg

  def configurePLL(self):
    if (self.activationFlag):
      self.xem.GetPLL22393Configuration(self.pll)
      self.pll.SetReference(48.0)
      self.pll.SetPLLParameters(0, 400, 48, True)
      self.pll.SetOutputSource(0, ok.PLL22393.ClkSrc_PLL0_0)
      self.pll.SetOutputDivider(0, 4)
      self.pll.SetOutputEnable(0, True)
      self.xem.SetPLL22393Configuration(self.pll)
      return self.pll.GetPLLFrequency(0)
    else :
      LogManager.Instance().write("class OpalKelly: PLL configuration failed")

  def loadFile(self, filename):
    if (self.activationFlag):
      output = self.xem.ConfigureFPGA(filename)
      if (self.xem.NoError == output):
        LogManager.Instance().write("class OpalKelly: Bit file loaded successfully")
      elif (self.xem.FileError == output):
        LogManager.Instance().write("class OpalKelly: Invalid file name")
    else :
      LogManager.Instance().write("class OpalKelly: No device found, loading bit file aborted")

  def isDeviceConnected(self):
    return self.activationFlag

  def setWireIn(self, addr, data):
    self.xem.SetWireInValue(addr, data)

  def updateWireIns(self):
    self.xem.UpdateWireIns()

  def activateTriggerIn(self, addr, bit):
    self.xem.ActivateTriggerIn(addr, bit)

  def writeToPipeIn(self, addr, buf):
    self.xem.WriteToPipeIn(addr, buf)

  def updateTriggerOuts(self):
    self.xem.UpdateTriggerOuts()

  def isTriggered(self, addr, trigMask):
    return self.xem.IsTriggered(addr, trigMask)

  def readFromBlockPipeOut(self, addr, size, buf):
    self.xem.ReadFromBlockPipeOut(addr, size, buf)
