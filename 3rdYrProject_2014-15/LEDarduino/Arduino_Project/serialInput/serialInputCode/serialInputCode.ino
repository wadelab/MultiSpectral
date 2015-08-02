/*
  State change detection (edge detection)
 	
 Often, you don't need to know the state of a digital input all the time,
 but you just need to know when the input changes from one state to another.
 For example, you want to know when a button goes from OFF to ON.  This is called
 state change detection, or edge detection.
 
 This example shows how to detect when a button or button changes from off to on
 and on to off.
 	
 The circuit:
 * pushbutton attached to pin 2 from +5V
 * 10K resistor attached to pin 2 from ground
 * LED attached from pin 13 to ground (or use the built-in LED on
   most Arduino boards)
 
 created  27 Sep 2005
 modified 30 Aug 2011
 by Tom Igoe

This example code is in the public domain.
 	
 http://arduino.cc/en/Tutorial/ButtonStateChange
 
 */

// this constant won't change:
const int ledPins[] = {1, 2, 3, 4, 5, 6, 7, 8};       // the pin that the LED is attached to

// Variables will change:
double startTime;
float modulationRateHz[] = {1, 2, 3.1, 4, 5.5, 6.9, 7, 8.3}; // Flicker rate of the LEDs when they're on
char incomingByte;   // for incoming serial data

void setup() {

  
  // initialize serial communication:
  Serial.begin(9600);
 
   startTime=millis();
     for (int thisPinIndex = 0; thisPinIndex < 8; thisPinIndex++) { 
         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         digitalWrite(ledPins[thisPinIndex], LOW);   
    
  } // Next pin
} // end of setup


void loop() {
// This runs forever
  if (Serial.available() > 0) {
                // read the incoming byte:
                incomingByte = Serial.read();
                startTime=millis(); // Reset the timing - this will look like a phase reset
                double p=incomingByte-'0';
                
                delay(p*100);
                
  }
      double cMillis=(millis()-startTime)/1000.0;
        for (int thisPinIndex = 0; thisPinIndex < 8; thisPinIndex++) { 
            double val = (sin(cMillis*2.0*3.1415927*modulationRateHz[thisPinIndex])*128+128.0);
      
            analogWrite(ledPins[thisPinIndex], val);
        } // Next pin
      

}









