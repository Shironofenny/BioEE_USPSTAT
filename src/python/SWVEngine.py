#! /usr/bin/env python
# -*- coding: utf-8 -*-

import threading
import time
import math

import LogManager
import CostiFPGA
import Constants

from OKByte import OKByte16

log = LogManager.Instance()
fpga = CostiFPGA.Instance()
constants = Constants.Instance()


class SWVEngine(object):

    def __init__(self):
        log.write("SWV Engine initializing")

        self.frequency = constants.SWV_DEFAULT_FREQ
        self.amp = constants.SWV_DEFAULT_AMP
        self.initE = constants.SWV_DEFAULT_STARTE
        self.endE = constants.SWV_DEFAULT_ENDE
        self.incrE = constants.SWV_DEFAULT_INCRE
        self.initWait = constants.SWV_DEFAULT_INITWAIT

        self.reValue = constants.SWV_DEFAULT_WE - self.initE
        self.weValue = constants.SWV_DEFAULT_WE

    def initSWV(self):
        log.write("Running SWV sweep")
        fpga.setWE1Value(self.weValue, False)
        fpga.setWE2Value(self.weValue, False)
        adcRefCode = math.floor(fpga.getADCRefValue() / constants.AVDD * constants.DAC_MAX_CODE)
        fpga.setSWVValue(int(adcRefCode))
        log.write("Sent ADC REF value")
        if self.initE > self.endE :
            fpga.setREValue(self.reValue - self.amp - self.incrE, True)

            initECode = math.floor((self.reValue - self.amp - self.incrE) / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(initECode))
            log.write("Sent Init E code")

            riseECode = math.floor(self.amp * 2 / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(riseECode))
            log.write("Sent Rise E code")

            fallECode = math.floor((self.amp * 2 - self.incrE) / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(fallECode))
            log.write("Sent Fall E code")

            stepMaxCode = math.floor(((self.endE - self.initE) / self.incrE) * 2 + 4)
        else :
            fpga.setREValue(self.reValue - self.amp + self.incrE, True)
            initECode = math.floor((self.reValue - self.amp + self.incrE) / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(initECode))
            log.write("Sent Init E code")

            riseECode = math.floor((self.amp * 2 - self.incrE) / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(riseECode))
            log.write("Sent Rise E code")

            fallECode = math.floor(self.amp * 2 / constants.AVDD * constants.DAC_MAX_CODE)
            fpga.setSWVValue(int(fallECode))
            log.write("Sent Fall E code")

            stepMaxCode = math.floor(((self.endE - self.initE) / self.incrE) * 2 + 3)
        timeMaxCode = math.floor(constants.OK_CLK_FREQ / self.frequency)
        fpga.setSWVValue(int(math.floor(timeMaxCode / 2**16)))
        fpga.setSWVValue(int(timeMaxCode % 2**16))
        log.write("Sent Time Max code")
        fpga.setSWVValue(int(stepMaxCode))
        log.write("Sent Step Max code")

        fpga.activateTriggerIn(constants.OK_BIT_SWV_START)
