from haws import *
import atexit
import time
uri = #insert websocket server address and port number
jws = JSONWebSocketClient("garter-ixt", uri)
pwm = 50
def atexit_handler():
  jws.close()
def die_handler(self, data):
  global pwm
  pwm+=5
  lives = data["lives"]
  if lives == 0:
   jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":1, "PWM": 100}}})
   jws.send({"api":{"command":"RELEASE","params":{}}})
   time.sleep(3)
   jws.send({"api":{"command":"ALL_PUMP_OFF","params":{}}})
  else:
    jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": pwm}}})
    jws.send(AIR["BLOW"])
    time.sleep(3)
    jws.send({"api":{"command":"PUMP_ON","params":{"pumpNumber":2, "PWM": pwm-20}}})
def ghostmode_handler(self, data):
  if data["state"] == "on":
    jws.send(AIR["PULSE_ON"])
  elif data["state"] == "off":
    jws.send(AIR["PULSE_OFF"])
    jws.send({"api":{"command":"ALL_PUMP_OFF","params":{}}})
def start_interaction():
  atexit.register(atexit_handler)
  jws.connect()
  jws.on("pacman", "DIE",  die_handler)
  jws.on("pacman", "GHOST_MODE", ghostmode_handler)
  jws.listen() 
if __name__ == '__main__':
  start_interaction()


