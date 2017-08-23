#! /usr/bin/env python
# -*- coding: utf-8 -*-

import math
import time
import threading
import binascii

from Queue import Queue

import OpalKelly
import LogManager
import Constants
from OKByte import OKByte16

# Alias to singletons
log = LogManager.Instance()
constants = Constants.Instance()

# Few lines to make it a (dirty, non-protected) singleton
# If you want to use LogManager in a singleton way, then the correct call would be:
# CostiFPGA.Instance().methodToCall(args)

instanceLock = threading.RLock()

_instance = None

def Instance():
  instanceLock.acquire()
  global _instance
  if _instance is None:
    _instance = CostiFPGA();
  instanceLock.release()
  return _instance

class CostiFPGA(OpalKelly.OpalKelly):

  def __init__(self):
    super(CostiFPGA, self).__init__()

    self.bitfileLoaded = False

    # Main Rlock to avoid simultanious multiple access to the xem3010
    self.xemlock = threading.RLock()
    self.datalock = threading.RLock()

    # Default DAC output values
    self.dac1Value = constants.WE1_DEFAULT_VOLTAGE
    self.dac2Value = constants.WE2_DEFAULT_VOLTAGE
    self.dac3Value = constants.RE_DEFAULT_VOLTAGE
    self.dac4Value = constants.ADCREF_DEFAULT_VOLTAGE

    self.switchState = constants.OK_DATA_SWDEFAULT

    # ADC data stream thread control
    self.adcDataThread = threading.Thread(target = self.acquireADCDataStream)
    self.stopADCDataStream = threading.Event()

    # Trigger manager thread control
    self.triggerManagerThread = threading.Thread(target = self.triggerOutManager)
    self.stopTriggerOutManager = threading.Event()

    # Triggers correspond to each trigger outs
    self.evDAC1AckData = threading.Event()
    self.evDAC1AckSet = threading.Event()
    self.evDAC2AckData = threading.Event()
    self.evDAC2AckSet = threading.Event()
    self.evADCFreqEx = threading.Event()
    self.evSDRAMReady = threading.Event()

    # Multi-thread data synchronization unit
    self.dataOutQueue = Queue()

  def setBitfileLoaded(self):
    self.datalock.acquire()
    self.bitfileLoaded = True
    self.datalock.release()

  def isBitfileLoaded(self):
    return self.bitfileLoaded

  def isReady(self):
    return (self.isDeviceConnected() and self.isBitfileLoaded())

  def reset(self):
    if not self.isReady() :
      log.write("No device with correct configuration is connected, abort resetting")
      return

    # Hardware reset
    self.setWireIn(constants.OK_DATA_RESET)
    self.updateWireIns()
    time.sleep(0.1)

    # Hardware de-reset
    self.setWireIn(constants.OK_DATA_IDLE)
    self.updateWireIns()

    # Clear all the events
    self.evDAC1AckSet.clear();
    self.evDAC1AckData.clear();
    self.evDAC2AckSet.clear();
    self.evDAC2AckData.clear();
    self.evSDRAMReady.clear();
    self.evADCFreqEx.clear();

  # -------------------------------------------
  # Getters / Setters for different DAC outputs
  # -------------------------------------------
  def setWE1Value(self, value, update=True):
    self.datalock.acquire()
    self.dac1Value = value
    if update : self.updateDacs()
    self.datalock.release()

  def setWE2Value(self, value, update=True):
    self.datalock.acquire()
    self.dac2Value = value
    if update : self.updateDacs()
    self.datalock.release()

  def setREValue(self, value, update=True):
    self.datalock.acquire()
    self.dac3Value = value
    if update : self.updateDacs()
    self.datalock.release()

  def setADCRefValue(self, value, update=True):
    self.datalock.acquire()
    self.dac4Value = value
    if update : self.updateDacs()
    self.datalock.release()

  def getADCRefValue(self):
    return self.dac4Value

  def getWE1Value(self):
    return self.dac1Value

  def getWE2Value(self):
    return self.dac2Value

  def getREValue(self):
    return self.dac3Value

  def flipSwitch1(self):
    self.switchState = self.switchState ^ constants.OK_DATA_SW[0]
    self.updateSwitches()

  def flipSwitch2(self):
    self.switchState = self.switchState ^ constants.OK_DATA_SW[1]
    self.updateSwitches()

  def flipSwitch3(self):
    self.switchState = self.switchState ^ constants.OK_DATA_SW[2]
    self.updateSwitches()

  def flipSwitch4(self):
    self.switchState = self.switchState ^ constants.OK_DATA_SW[3]
    self.updateSwitches()

  def getSwitchState(self, i):
    # Simple robustness test
    if i < 1 or i > 4 :
      return False
    state = self.switchState & constants.OK_DATA_SW[i-1]
    return state != 0x0000

  def updateSwitches(self):
    self.setWireIn(self.switchState)
    self.updateWireIns()
    self.activateTriggerIn(constants.OK_BIT_CTRL_UPDATE)

  def updateDacs(self):
    self.datalock.acquire()
    if not self.isReady() :
      log.write("No device with correct configuration is connected, abort updating the DAC values")
      return

    dac1Int = math.floor(self.dac1Value / constants.AVDD * constants.DAC_MAX_CODE)
    dac2Int = math.floor(self.dac2Value / constants.AVDD * constants.DAC_MAX_CODE)
    dac3Int = math.floor(self.dac3Value / constants.AVDD * constants.DAC_MAX_CODE)
    dac4Int = math.floor(self.dac4Value / constants.AVDD * constants.DAC_MAX_CODE)

    # Initialize the byte transfer buffer
    dacDataBuffer = bytearray(6)
    dacDataBuffer[1] = int(dac1Int / 16)
    dacDataBuffer[0] = int(dac3Int / 16)
    dacDataBuffer[3] = int(dac1Int % 16) * 16 + int(dac2Int / 256)
    dacDataBuffer[2] = int(dac3Int % 16) * 16 + int(dac4Int / 256)
    dacDataBuffer[5] = int(dac2Int % 256)
    dacDataBuffer[4] = int(dac4Int % 256)

    # Sending the buffer through pipe in
    #log.write("Sending DAC data, and waiting for hardware acknowledgement ...")
    self.writeToPipeIn(constants.OK_ADDR_PIPEIN_DAC, dacDataBuffer)

    # Waiting for acknowledgement
    dac1ack = False
    dac2ack = False
    for i in range(constants.TRIGGER_BACK_CYCLE):
      if self.evDAC1AckData.isSet() :
        dac1ack = True
        self.evDAC1AckData.clear()
      if self.evDAC2AckData.isSet() :
        dac2ack = True
        self.evDAC2AckData.clear()
      if dac1ack and dac2ack:
        #log.write("Acknowledgement received from DACs after " + str(i) + " cycles, setting the output ...")
        break
      time.sleep(constants.TRIGGER_OUT_CHECK_INTERVAL)

    if ( not dac1ack ) or ( not dac2ack ):
      if dac1ack:
        log.write("Failed to receive acknowledgement from DAC2, write action aborted.")
      elif dac2ack:
        log.write("Failed to receive acknowledgement from DAC1, write action aborted.")
      else :
        log.write("Failed to receive acknowledgement from both DACs, write action aborted.")

    self.activateTriggerIn(constants.OK_BIT_DAC_SET)

    dac1ack = False
    dac2ack = False
    for i in range(constants.TRIGGER_BACK_CYCLE):
      if self.evDAC1AckSet.isSet() :
        dac1ack = True
        self.evDAC1AckSet.clear()
      if self.evDAC2AckSet.isSet() :
        dac2ack = True
        self.evDAC2AckSet.clear()
      if dac1ack and dac2ack:
        #log.write("Acknowledgement received from DACs after " + str(i) + " cycles, values updated to the outputs: DAC1 = " +
        #    str(self.dac1Value) + " , DAC2 = " + str(self.dac2Value) + " , DAC3 = " + str(self.dac3Value) + " , DAC4 = " + str(self.dac4Value))
        break
      time.sleep(constants.TRIGGER_OUT_CHECK_INTERVAL)

    if ( not dac1ack ) or ( not dac2ack ):
      if dac1ack:
        log.write("Failed to receive acknowledgement from DAC2, set action aborted.")
      elif dac2ack:
        log.write("Failed to receive acknowledgement from DAC1, set action aborted.")
      else :
        log.write("Failed to receive acknowledgement from both DACs, set action aborted.")

    self.datalock.release()

  def configureADC(self):
    if not self.isReady() :
      log.write("No device with correct configuration is connected, abort configuring the ADC")
      return

    adcBuf = OKByte16(2)
    adcBuf[0] = constants.ADC_CONFIGURE_CODE#0xFF04
    adcBuf[1] = 0x0000
    self.writeToPipeIn(constants.OK_ADDR_PIPEIN_ADC, adcBuf.toByteArray())

  def getADCData(self):
    if not self.isReady() :
      log.write("No device with correct configuration is connected, abort getting Data from ADC")
      return

    adcBuf = OKByte16(constants.OK_PIPEOUT_TRANSFERSIZE)
    self.readFromBlockPipeOut(constants.OK_ADDR_PIPEOUT, constants.OK_PIPEOUT_BLOCKSIZE, adcBuf.toByteArray())
    return adcBuf

  def getDataQueueOut(self):
    if self.dataOutQueue.empty():
      return None
    else :
      return self.dataOutQueue.get()

# ---------------------------------------------------------
# The following functions are related to reading ADC data
# from a separate thread
# ---------------------------------------------------------

  def triggerOutManager(self):
    """ The only function that take care of trigger outs. It will check trigger outs
        periodically and set corresponding events if a trigger out is detected.
        This thread will set the triggers, and threads responsible for action will
        clear them if an action is taken.

        This thread also take care of exception trigger outs from FPGA
    """
    while not self.stopTriggerOutManager.wait(constants.TRIGGER_OUT_CHECK_INTERVAL):
      # Update all trigger outs
      self.updateTriggerOuts()
      if self.isTriggered(constants.OK_BIT_DAC1_ACK_SET):
        self.evDAC1AckSet.set()
      if self.isTriggered(constants.OK_BIT_DAC1_ACK_DATA):
        self.evDAC1AckData.set()
      if self.isTriggered(constants.OK_BIT_DAC2_ACK_SET):
        self.evDAC2AckSet.set()
      if self.isTriggered(constants.OK_BIT_DAC2_ACK_DATA):
        self.evDAC2AckData.set()
      if self.isTriggered(constants.OK_BIT_SDRAM_READY):
        self.evSDRAMReady.set()
      if self.isTriggered(constants.OK_BIT_ADC_FREQ_EX):
        self.evADCFreqEx.set()

      # Handle exception triggers
      if self.evADCFreqEx.isSet():
        log.write("ADC Read frequency deviation detected. FFT might not be reliable for the time being")
        self.evADCFreqEx.clear()

  def startTriggerOutManagerThread(self):
    if not self.triggerManagerThread.isAlive():
      self.triggerManagerThread = threading.Thread(target = self.triggerOutManager)

    try :
      self.triggerManagerThread.start()
    except RuntimeError as e:
      log.write("Runtime Error: ({0}): {1}".format(e.errno, e.strerror))
    else :
      self.stopTriggerOutManager.clear()

  def stopTriggerOutManagerThread(self):
    self.stopTriggerOutManager.set()

# ---------------------------------------------------------
# The following functions are related to reading ADC data
# from a separate thread
# ---------------------------------------------------------

  def acquireADCDataStream(self):
    """ Get ADC data from SDRAM periodically
    """
    while not self.stopADCDataStream.wait(constants.ADC_DATA_CHECK_INTERVAL):
      if self.evSDRAMReady.isSet() :
        data = self.getADCData()
        self.evSDRAMReady.clear()
        self.dataOutQueue.put(data)
      else :
        pass

  def startADCDataStreamThread(self):
    if not self.adcDataThread.isAlive():
      self.adcDataThread = threading.Thread(target = self.acquireADCDataStream)

    try :
      self.adcDataThread.start()
    except RuntimeError as e:
      log.write("Runtime Error: ({0}): {1}".format(e.errno, e.strerror))
    else :
      self.stopADCDataStream.clear()

  def stopADCDataStreamThread(self):
    self.stopADCDataStream.set()

# ---------------------------------------------------------
# The functions below are the interface to the opal kelly
# (overloaded from the inherited OpalKelly class)
# Since this program may use multi-thread, all communicate
# with the single Opal Kelly instance, any call to self.xem
# needs Rlock
# ---------------------------------------------------------
  def setWireIn(self, data):
    """ Thread save version of setWireIn
    """
    self.xemlock.acquire()
    try :
      self.xem.SetWireInValue(constants.OK_ADDR_CONTROL, data)
    except :
      log.write("FPGA unable to write wire inputs, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def setSWVValue(self, data):
    """ Thread save version of setWireIn
    """
    self.xemlock.acquire()
#    try :
    self.xem.SetWireInValue(constants.OK_ADDR_SWV, data)
    self.xem.UpdateWireIns()
#    except :
    #log.write("FPGA unable to write wire inputs, perhaps a multi-thread writing conflict")
    try :
      self.xem.ActivateTriggerIn(constants.OK_ADDR_TRIGIN, constants.OK_BIT_SWV_UPDATE)
    except :
      log.write("FPGA unable to activate trigger in, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def updateWireIns(self):
    """ Thread save version of updateWireIns
    """
    self.xemlock.acquire()
    try :
      self.xem.UpdateWireIns()
    except :
      log.write("FPGA unable to update wire ins, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def activateTriggerIn(self, bit):
    """ Thread save version of activateTriggerIn
    """
    self.xemlock.acquire()
    try :
      self.xem.ActivateTriggerIn(constants.OK_ADDR_TRIGIN, bit)
    except :
      log.write("FPGA unable to activate trigger in, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def updateTriggerOuts(self):
    """ Thread save version of updateTriggerOuts
    """
    self.xemlock.acquire()
    try :
      self.xem.UpdateTriggerOuts()
    except :
      log.write("FPGA unable to update trigger outs, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def isTriggered(self, bit):
    """ Thread save version of IsTriggered
    """
    self.xemlock.acquire()
    try :
      result = self.xem.IsTriggered(constants.OK_ADDR_TRIGOUT, bit)
    except :
      log.write("FPGA unable to is triggered, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

    return result

  def writeToPipeIn(self, addr, buf):
    """ Thread save version of IsTriggered
    """
    self.xemlock.acquire()
    try :
      self.xem.WriteToPipeIn(addr, buf)
    except :
      log.write("FPGA unable to write to pipein, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()

  def readFromBlockPipeOut(self, addr, size, buf):
    """ Thread save version of IsTriggered
    """
    self.xemlock.acquire()
    try :
      self.xem.ReadFromBlockPipeOut(addr, size, buf)
    except :
      log.write("FPGA unable to read block pipe out, perhaps a multi-thread writing conflict")
    finally :
      self.xemlock.release()
