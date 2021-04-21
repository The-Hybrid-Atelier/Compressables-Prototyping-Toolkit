from haws import *
import atexit
import time
uri = #insert websocket server address and port number
jws = JSONWebSocketClient("elbow-brace-ixt", uri)
rep = 0
def atexit_handler():
  jws.close()
def squeeze_handler(self,data):
  global rep
  if rep == 0:
    message={"event":"METER", "value": rep, "segments": 5, "gap": 10, "unit": "reps", "size": 150, "font": "Avenir"}
    jws.send(message)
  rep+=1
  message={"event":"METER", "value": rep, "segments": 5, "gap": 10, "unit": "reps", "size": 150, "font": "Avenir"}
  jws.send(message)
  if rep == 5:
    jws.send({"api":{"command":"RELEASE","params":{}}})
    time.sleep(5)
    jws.send({"api":{"command":"ALL_PUMP_OFF","params":{}}})
    rep = 0
def start_interaction():
  atexit.register(atexit_handler)
  jws.connect()
  jws.on("gesture-recognizer", "UN_SQUEEZE", squeeze_handler)
  message={"event":"METER", "value": 0, "segments": 5, "gap": 10, "unit": "reps", "size": 150, "font": "Avenir"}
  jws.send(message)
  jws.listen() 
if __name__ == '__main__':
  start_interaction()

