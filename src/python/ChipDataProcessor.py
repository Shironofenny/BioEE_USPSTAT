#! /usr/bin/env python
# -*- coding: utf-8 -*-

import LogManager
import Constants
import ListQueue

# Nickname for the singleton CostiFPGA
log = LogManager.Instance()
constants = Constants.Instance()

class ChipDataProcessor(object):

  def __init__(self):
    self.data = ListQueue.ListQueue(constants.NUM_DATA_DISPLAY)
    self.bitGuess = 0
    self.state = 0
    self.dataIndex = 0
    self.timeEndOfProtocol = 0
    self.protocolCount = 0
    
  def pushData(self, data):
    # A state engine is designed to trac the incomming data and decipher it.
