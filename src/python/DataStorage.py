#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import threading

import LogManager
import Constants

import FeUtils as utils

# Nickname for the singleton CostiFPGA
log = LogManager.Instance()
constants = Constants.Instance()

save_path = utils.feFindDir(constants.DATA_SAVE_DIR, 3)
if save_path == None :
	os.mkdir("data")
	save_path = "data"

instanceLock = threading.RLock()

_instance = None

def Instance():
  instanceLock.acquire()
  global _instance
  if _instance is None:
    _instance = DataStorage();
  instanceLock.release()
  return _instance

class DataStorage(object):
	
    def __init__(self):
        self.filehandle = [None] * 8
        self.analogFileHandle = None
        for i in constants.DATA_SAVED_CHANNELS :
            self.filehandle[i] = open(save_path + "/" + constants.DATA_SAVE_FILE_PREFIX + constants.DATA_SAVE_FILE_SUFFIX[i], 'w')

        self.analogFileHandle = open(save_path + "/" + constants.DATA_SAVE_FILE_PREFIX + constants.DATA_SAVE_FILE_ANALOG_SUFFIX, 'w')

    def pushData(self, channel, data):
        if channel in constants.DATA_SAVED_CHANNELS :
            #print "Channel" + str(channel) + "written"
            self.filehandle[channel].write(str(data) + '\n')
        if channel == 'analog' :
            self.analogFileHandle.write(str(data) + '\n')

    def close(self):
        for i in constants.DATA_SAVED_CHANNELS :
            self.filehandle[i].close()

        self.analogFileHandle.close()
