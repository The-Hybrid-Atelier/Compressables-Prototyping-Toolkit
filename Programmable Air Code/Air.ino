#include "programmable_air.h"
#include <Adafruit_NeoPixel.h>
#include "behaviors.h"
Adafruit_NeoPixel px = Adafruit_NeoPixel(3, neopixelPin, NEO_GRB + NEO_KHZ800);
#define DEBUG 1
#define BAUDRATE 115200

char c;
int buff;
bool pressure = false;
bool pulse = false;
int pumpNumber;
int pwm;
bool first = true;
void setup() {
  initializePins();
  px.begin();
  Serial.begin(BAUDRATE);

}

void read_pressure()
{
  int pressure = readPressure(1,50);
  byte pressure_map = map(pressure, 0, 1024, 0, 255); //going from 10 to 8 bits resolution
  Serial.write(pressure_map);
}

void check_end(char c)
{
  while(c!= '\n')
  {
    if(Serial.available() >0)
    c = Serial.read(); 
    
  }
}

void pumpOn(char c)
{
  while(c != '\n')
    {
     if(Serial.available()>0)
     {
      buff = Serial.read();
      if(buff == '\n')
      {
        c = buff;
        break;
      }
      else
      {
        c = 'x';
        if(first)
          {
            pumpNumber = buff;
            first = false;
          }
        else
          {
          pwm = buff;
          first = true;
          }
       }
      
    }    
  }
  switchOnPump(pumpNumber, pwm); 
}

void pumpOff(char c)
{
  while(c!= '\n')
  {
    if(Serial.available()>0)
    {
      buff = Serial.read();
      if(buff == '\n')
      {
        c = buff;
        break;
      }
      else
      {
        pumpNumber = buff;
      }
    }
  }
 
  switchOffPump(pumpNumber);
}

void seal()
{
  closeAllValves();

}
void check()
{
  setAllValves(OPEN); 
}
void handler()
{
  // THE FIRST CHARACTER OF A COMMAND LOGIC  
  c = Serial.read();
  //Serial.println(c, HEX);
  if(c == '1')
  {
    pumpOn(c);
  }
  if (c== '2')
  {
    pumpOff(c);
  }
  if(c == '3')
  {
    switchOffPumps();
    check_end(c);
  }
  if(c == '4')
  {
    pulse = true;
    check_end(c);
  }
  if(c == '5')
  {
    pulse = false;
    check_end(c);
  }
  if(c == '6')
  {
    pressure = true;
    check_end(c);
  }
  if(c == '7')
  {
    pressure = false;
    check_end(c);
  }
  if(c == '8')
  {
    blow();
    check_end(c);
  }
  if(c == '9')
  {
    suck();
    check_end(c);
  }
  if(c == 'a')
  {
    vent();
    check_end(c);
  }
  if(c == 'b')
  {
    seal();
    check_end(c);
  }
  if(c == 'c')
  {
    check();
    check_end(c);
  }

}
void loop() {
  if(Serial.available()>0) handler();
  if(pressure) read_pressure();
  if(Serial.available()>0) handler();
  if(pulse) pulsing();
}
