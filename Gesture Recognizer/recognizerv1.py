from simple_api import *
import atexit, string, numpy, math, pprint, time
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import pandas as pd
import numpy as np
from scipy.signal import butter,filtfilt, savgol_filter, argrelextrema
from random import random

DEVICE_NAME= "programmable-air"
# GLOBALS

servers = {
  "cloud": #enter cloud server uri
}

uri = servers["cloud"]
jws = JSONWebSocketClient("gesture-recognizer", uri)
pp = pprint.PrettyPrinter(indent=4)

STATES = ["SQUEEZE", "UNSQUEEZE",  "NO SQUEEZE", "SQUEEZE HOLD", "HIGH PRESSURE"]
state = STATES[2]
pause = False


mean_history = []

# FUNCTIONS
def atexit_handler():
  jws.send({"api":{"command":"ALL_PUMP_OFF","params":{}}})
  jws.send(pressure_OFF)
  jws.close()


def startup(callback):
  print("STARTING UP...")
  jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": 50}}})
  jws.send(AIR["BLOW"])
  time.sleep(3)
  jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": 40}}})
  callback()


# CLASSIFY
# Given a cleaned activity window, classify different bladder actions
# emit events.
def classify(data, clean_data):
  global state
  global STATES
  global pause
  global mean_history

  mean_history.append(np.mean(clean_data))
  if(len(mean_history) > 3):
    mean_history.pop(0)


  baseline_local = np.mean(mean_history)
  mean = np.mean(clean_data)
  canny_data = np.convolve(clean_data, [2, 0, -2], 'same')
  canny_sum = np.sum(canny_data)

  is_squeezed = canny_sum >= 2 and mean > baseline_local
  print("%i %2.2f CS: %2.0f M: %2.2f" %(is_squeezed, baseline_local, canny_sum, mean))

  # If the difference in magnitude within a single window is > than a threshold
  # and the compressable is not in a squueze state
  if is_squeezed and state != STATES[0]:
    c_event = {"event": "SQUEEZE", "bg": "pink"}
    print("SQUEEZE")
    jws.send(c_event)
    state = STATES[0]
  else:
    state = STATES[1]
  
# Returns clean window
def clean(win):
  n = len(win)
  # 1/6 kernel size + odd width, fitted least squares, polynomial order 3
  l = int(n/6)
  if l%2 == 0: 
    l = l + 1

  try:
    smooth = savgol_filter(win, l, 3)
    return smooth
  except:
    return win
  

def prep_window(value):
  global window
  window.extend(value) #ADD MESSAGE REGARDLESS OF SIZE
  #UPDATING LIST BY REMOVING HEAD
  if len(window) >= WINDOW_BUFFER_LEN:
    window = window[-WINDOW_BUFFER_LEN:]
    cleanable = True
  else:
    cleanable = False
  return window, cleanable

  
def recognition_routine_handler(self, message):
  global window
  global pause
  window, cleanable = prep_window(message["data"])

  if cleanable:
    clean_window = clean(window)
    if not pause:
      classify(window, clean_window)
    else:
      c_event = {"event": "INTERACT"}
      jws.send(c_event)
      print("INTERACT")
      time.sleep(5)
      pause = False

# Connects to the live HRP system
pressure_ON = {"api":{"command":"PRESSURE_ON","params":{}}}
pressure_OFF = {"api":{"command":"PRESSURE_OFF","params":{}}}

def start_recognizer():
  atexit.register(atexit_handler)
  jws.connect()
  jws.send(pressure_ON)
  # BINDING TO EVENTS
  jws.on(DEVICE_NAME, "read-pressure", recognition_routine_handler)
  startup(jws.listen)
  # NOTHING AFTER THIS LINE! LISTEN BLOCKS!


################  GR HYPERPARAMETERS  ########################

# PROCESSING VARIABLES
WINDOW_BUFFER_LEN = 32
window = []
PACKET_SIZE = 8
if __name__ == '__main__':
  plt.ion()
  start_recognizer()
