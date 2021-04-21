
void inflate()
{
  
  switchOnPump(2, 60); 
  switchOffPump(1);  
  blow();
  delay(2000); 
  switchOnPump(2, 30);
}

void deflate()
{
  switchOnPump(1,100);
  setAllValves(OPEN);
  delay(3000);
  //switchOffPumps();
}

void pulsing()
{
  inflate();
  delay(500);
  deflate();
  delay(500);
}
