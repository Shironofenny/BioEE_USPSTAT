#! /usr/bin/env python
# -*- coding: utf-8 -*-

class LogFile(object):
  # A subclass of file just to have a more convienient way to write logs
  def __init__(self, name, mode = 'r'):
    self.name = name
    self.mode = mode

  def writeLog(self, string):
    self.file = open(self.name, self.mode)
    self.file.write(string + '\n')
    self.file.close()
