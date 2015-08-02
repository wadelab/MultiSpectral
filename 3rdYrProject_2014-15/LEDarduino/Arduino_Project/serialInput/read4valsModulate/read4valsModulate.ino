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
const int ledPins[] = {8,9,11,12};       // the pin that the LED is attached to

// Variables will change:
double startTime;
float modulationRateHz[] = {1,1,1,1}; // Flicker rate of the LEDs when they're on
int LEDamps[] = {255,255,255,255,};
int LEDactive[] = {1,1,1,1};

char incomingByte;   // for incoming serial data

void setup() {

  
  // initialize serial communication:
  Serial.begin(9600);
 
   startTime=millis();
     for (int thisPinIndex = 0; thisPinIndex < 4; thisPinIndex++) { 
         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         analogWrite(ledPins[thisPinIndex], 0);   
         delay(100);
  } // Next pin
} // end of setup


void loop() {
// This runs forever
  analogWriteResolution(12);

  if (Serial.available() > 0) {
        startTime=millis(); // Reset the timing - this will look like a phase reset

    for (int thisByte=0;thisByte<4;thisByte++) {
    
                // read the incoming byte:
                LEDamps[thisByte] = Serial.read();
          } // Next byte to read
        } // End check on whether a byte is available...
             
                /* We now have 7 amplitudes - one for each of the LEDs. We will modulate them with these amplitudes
                constantly. Until the end of time.
                */
              
                
    
      double cMillis=(millis()-startTime)/1000.0;
       
        for (int thisPinIndex = 0; thisPinIndex < 4; thisPinIndex++) { 
            int val = (sin(cMillis*2.0*3.1415927*modulationRateHz[thisPinIndex])*(LEDamps[thisPinIndex]/2)+128.0);
      
            analogWrite(ledPins[thisPinIndex], val);
        } // Next pin
      

}









