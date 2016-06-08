/*
This code does one thing: It reads 7 values from the serial port at a time, then uses those values as amplitudes 
for a flickering pulse on the LEDs. The pulse lasts 1 second
 */

// this constant won't change:
const int ledPins[] = { 2,3,4,5,6,7,8 };       // the pin that the LED is attached to

// Variables will change:
unsigned long startTime;
double modulationRateHz[] = {2,2,2,2,2,2,2}; // Flicker rate of the LEDs when they're on
byte LEDamps[] = {0,0,0,0,0,0,0}; // How much each LED flickers (from 0 to 256) about the baseline. Obviously if the baseline is 128, the flicker amplitude must be no more than 128.
byte LEDbaseLevel[] = {128,128,128,128,128,128,128}; // These are the baseline levels of the LEDs. They are set through Matlab inputs so these values here are just examples
long pulseDuration = 3000; // How long each pulse lasts in ms
long elapsedTimeMilliSecs = 0; 
int halfAmp = 128; // Half the maximum amplitude. It will be bigger if we use 12 bit precision
void setup() {

  
  // initialize serial communication:
      Serial.begin(9600);
     for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { 
         analogWriteResolution(8);

         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         analogWrite(ledPins[thisPinIndex], 0);   
         delay(100); // To make it look fancy
         
         
  } // Next pin
} // end of setup


void loop() {
// This runs forever  
  int bytesRead=0; // Have we read from the serial port recently? 0 for no, 1 for yes
  while (bytesRead<1) { // Keep looping until there's something available to read
      if (Serial.available() > 0) {
        Serial.readBytes(LEDamps,7); // First 7 bytes are the modulation amps
        Serial.readBytes(LEDbaseLevel,7); // Second 7 bytes are the baselines.

        bytesRead=1; // Tell the loop we've read something
      }  // End while statement - we will stop when we have 7 bytes
  }
  Serial.flush(); // Not sure if we need this but it can't hurt
   
                /* We now have 7 amplitudes - one for each of the LEDs. We will modulate them with these amplitudes
                for one second (or pulseDuration) - then go back to the start of the loop
                */
              
       // Here we loop for one second
     startTime=millis(); // Log the current time in ms
    elapsedTimeMilliSecs=0; // This will count up until it reaches the pulseDuration

    while (elapsedTimeMilliSecs < pulseDuration) { // Keep checking to see how long we've been in this loop (in ms)
       elapsedTimeMilliSecs=(millis()-startTime); // Compute how long it's been in this loop in ms. We will terminate
      // when the elapsed time is greater than the pulse width that we asked for.
       
        for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { // Loop (very quickly) over all pins
            int val = sin(double(elapsedTimeMilliSecs)*0.0062832*modulationRateHz[thisPinIndex])*(double(LEDamps[thisPinIndex])/2.0)+LEDbaseLevel[thisPinIndex];
      
            analogWrite(ledPins[thisPinIndex], val); // Write value to the pin
        } // Next pin
    } // end while loop;
    
    
    // Set everything to zero afterwards. We could also set to baseline levels...
      for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { 
                    analogWrite(ledPins[thisPinIndex], 0);
      } // next pin to zero 
      

} // end function









