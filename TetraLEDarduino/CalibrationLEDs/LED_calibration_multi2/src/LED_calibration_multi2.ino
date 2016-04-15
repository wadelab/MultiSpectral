#include <Arduino.h>

// turn on only the specified LED to run calibration (using the Jaz)

void setup() {
  // put your setup code here, to run once:

const int LEDs[] = {8,9,10,11,12}; //the LED pins available
int nPins = 5;
int ledOff = 0;
int ledOn = 255;

int ledVals[]={0,0,0,255,128}; // specify which LED you want on

    for (int thisPin = 0; thisPin < nPins; thisPin++) {
        pinMode(LEDs[thisPin], OUTPUT);

        // turn each pin to its value
        analogWrite(LEDs[thisPin], ledVals[thisPin]);
        delay(100);
    } // next LED


  }


void loop() {
  // put your main code here, to run repeatedly:


}
