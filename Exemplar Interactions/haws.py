import json, os, wave, struct, time, glob
import pprint
import websocket
import numpy as np
from websocket import create_connection
import itertools

class JSONWebSocketClient:
  def __init__(self, name, uri):
    self.uri = uri
    self.on_register = {}
    self.name = name


  def connect(self):
    self.ws = create_connection(self.uri)
    print("Listening on %s"% (self.uri))
    self.ws.settimeout(1)
    print("Timeout is %f"%(self.ws.gettimeout()))
    self.greet()

  def greet(self):
    greeting = {}
    greeting["name"] = self.name
    greeting["event"] = "greeting" 
    self.send(greeting)

  def close(self):
    self.ws.close()

  def listen(self):
    raw_msg = ""  
    if self.ws:
      try:
        raw_msg = self.ws.recv()
      except:
        raw_msg = None
      if raw_msg:
        msg = json.loads(raw_msg)
        if not "data" in msg:
          print("Listening << ", msg, " \n")

        # IF API COMMAND
        if "sender" in msg and "api" in msg:
          key = msg["sender"] + msg["api"]["command"]
          if key in self.on_register:
            action, callback = self.on_register[key]
            if msg["api"]["command"] == action:
              #print("Listening << ", msg, " \n")
              callback(self, msg)

        if "sender" in msg and "event" in msg:
          key = msg["sender"] + msg["event"]
          if key in self.on_register:
            action, callback = self.on_register[key]
            if "event" in msg:
              if msg["event"] == action:
                #print("Listening << ", msg, " \n")
                callback(self, msg)

  def send(self, msg):
    if hasattr(self, "ws"):
      self.ws.send(json.dumps(msg))
    if "debug" in msg:
      if msg["debug"]:
        print("Sending >> ", msg)
  def on(self, sender_name, action, callback):
    self.on_register[sender_name + action] = (action, callback)
