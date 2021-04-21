from haws import *
import atexit
import time
uri = #insert websocket server address and port number
jws = JSONWebSocketClient("stress-glove-ixt", uri)
def atexit_handler():
  jws.close()
def squeeze_handler(self,data):
  jws.send({"api":{"command":"PUMP_OFF","params":{"pumpNumber":1}}})
  jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": 90}}})
  jws.send(AIR["BLOW"])
  time.sleep(3)
  jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": 60}}})
def start_interaction():
  atexit.register(atexit_handler)
  jws.connect()
  jws.on("gesture-recognizer", "UN_SQUEEZEA", squeeze_handler)
  jws.listen() 
if __name__ == '__main__':
  start_interaction()


