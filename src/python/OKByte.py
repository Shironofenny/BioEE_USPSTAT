import math

class OKByte16():

  def __init__(self, length = 0):
    self.length = length
    self.data = bytearray(length*2)

  def append(self, appendedByte):
    self.data.append(appendedByte%256)
    self.data.append(appendedByte/256)

  def __getitem__(self, index):
    if isinstance(index, int):
      return (self.data[index*2+1] * 256 + self.data[index*2])
    elif isinstance(index, slice):
      start, stop, step = index.indices(len(self.data))
      return [ (self.data[i*2+1] * 256 + self.data[i*2]) for i in range(start, stop, step) ]
    else :
      raise TypeError("Index must be either int or slice")

  def __setitem__(self, index, value):
    if ( (not isinstance(value, int)) and (not isinstance(value, list))):
      raise TypeError("Value must be an integer or list of integers")
    else :
      if isinstance(index, int):
        self.data[index*2+1] = value/256
        self.data[index*2] = value%256
      elif isinstance(index, slice):
        start, stop, step = index.indices(len(self.data))
        for i in range(start, stop, step): 
          self.data[i*2+1] = value[i]/256
          self.data[i*2] = value[i]%256
      else :
        raise TypeError("Index must be either int or slice")

  def toByteArray(self):
    return self.data

  def getSize(self):
    return self.length
