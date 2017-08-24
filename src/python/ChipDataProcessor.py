#! /usr/bin/env python
# -*- coding: utf-8 -*-

import LogManager
import Constants
import ListQueue
import DataStorage

# Nickname for the singleton CostiFPGA
log = LogManager.Instance()
constants = Constants.Instance()
dataInterface = DataStorage.Instance()

class ChipDataProcessor(object):

    def __init__(self):
        self.dataList = ListQueue.ListQueue(constants.NUM_DATA_DISPLAY)
        self.bitGuess = [0] * 9

        self.state = 0

        self.dataIndex = 0
        self.timeEndOfProtocol = 0
        self.protocolCount = 0

        self.previousData = 1
        self.currentData = 0

        self.voltageMiddle = constants.DP_VMIDDLE
        
        # Dictionary based processor
        self.processor = {
            0 : self.waitForNextFrame,
            1 : self.verifyProtocolL,
            2 : self.verifyProtocolH,
            3 : self.decodeBitL,
            4 : self.decodeBitH
        }
    
    def getData(self):
        return self.dataList.getData()

    def pushData(self, data):
        # A state engine is designed to trac the incomming data and decipher it.
        
        self.dataIndex = self.dataIndex + 1
        self.processor[self.state]()
        self.previousData = self.currentData

    def waitForNextFrame(self):
        if (self.currentData < self.previousData) :
            self.state = 1
            self.dataIndex = 0

    def verifyProtocolL(self):
        if (self.currentData == 1) :
            self.protocolCount = self.protocolCount + 1
            if (self.protocolCount == 4) : 
                self.state = 3
                self.protocolCount = 0
            else :
                self.state = 2

    def verifyProtocolH(self):
        if (self.currentData == 0) :
            if (self.dataIndex < constants.DP_BIT_MAX_LENGTH ) :
                self.state = 1
                self.dataIndex = 0
            else :
                self.protocolCount = 0
                self.state = 1
                self.dataIndex = 0

    def decodeBitL(self):
        if (self.currentData == 0) :
            nHalfBits = round(float(self.dataIndex) / constants.DP_BIT_HALF_LENGTH)
            if (nHalfBits % 2 == 1):
                nBits = (nHalfBits - 1) / 2
            else :
                nBits = nHalfBits / 2;

            self.bitGuess[nBits] = 1
            self.state = 4
        if (self.dataIndex > constants.DP_BIT_FULL_LENGTH * constants.DP_FRAME_MAX_NBIT) :
            self.state = 0
            if (sum(self.bitGuess) % 2 == 1) :
                log.write("Parity check failed, possibly decoded in a wrong way")

            # Converting bit data into integer
            analogValue = sum([self.bitGuess[7-i] << i for i in range(7)])
            analogData.push(analogValue)
            dataInterface.pushData('analog', analogValue)
            self.bitGuess = [0] * 9

    def decodeBitH(self):
        if (self.currentData == 1) : 
            self.state = 3
