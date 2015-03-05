/*
This code does one thing: It reads 7 values from the serial port at a time, then uses those values as amplitudes 
for a flickering pulse on the LEDs. The pulse lasts 3 second
The name has a number in it _012715_1 that should match some matlab code somewhere...
TODO : Add noise (possibly) to increase thresholds and mask stim onset. Or allow a Gaussian temporal envelope.

 */

// this constant won't change:
const int ledPins[] = {8,9,11,12};       // the pin that the LED is attached to

// Variables will change:
unsigned long startTime;
double modulationRateHz = 4; // Flicker rate of the LEDs when they're on
byte LEDamps[] = {0,0,0,0}; // How much each LED flickers (from 0 to 256) about the baseline. Obviously if the baseline is 128, the flicker amplitude must be no more than 128.
byte LEDbaseLevel[] = {0,0,0,0}; //{32,144,192,128}; // These are the baseline levels of the LEDs. They are set through Matlab inputs so these values here are just examples
long pulseDuration = 1000; // How long each pulse lasts in ms
long elapsedTimeMilliSecs = 0; 
int halfAmp = 128; // Half the maximum amplitude. It will be bigger if we use 12 bit precision
int nPins = 4;
 
void setup() {

       //    analogWriteResolution(8);

  // initialize serial communication:
      Serial.begin(9600);
     for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 

         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         analogWrite(ledPins[thisPinIndex], LEDbaseLevel[thisPinIndex]);   
         delay(100); // To make it look fancy
         
         
  } // Next pin
  delay(1000);
} // end of setup


void loop() {
// This runs forever  
  int bytesRead=0; // Have we read from the serial port recently? 0 for no, 1 for yes
  
    Serial.flush(); // Not sure if we need this but it can't hurt

  while (bytesRead<1) { // Keep looping until there's something available to read
      if (Serial.available() > 0) {
          Serial.readBytes(LEDamps,nPins); // First 7 bytes are the modulation amps
          Serial.readBytes(LEDbaseLevel,nPins); // Second 7 bytes are the baselines.

          bytesRead=1; // Tell the loop we've read something
      }  // End while statement - we will stop when we have 7 bytes
  }
  
  Serial.flush(); // Not sure if we need this but it can't hurt
   
                /* We now have 7 amplitudes - one for each of the LEDs. We will modulate them with these amplitudes
                for one second (or pulseDuration) - then go back to the start of the loop
                */
             for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 
                   analogWrite(ledPins[thisPinIndex], 0);   // To add in a quick black flicker
              }
              
             delay(100);
            
       // Here we loop for one second
     startTime=millis(); // Log the current time in ms
     elapsedTimeMilliSecs=0; // This will count up until it reaches the pulseDuration

    while (elapsedTimeMilliSecs < pulseDuration) { // Keep checking to see how long we've been in this loop (in ms)
       elapsedTimeMilliSecs=(millis()-startTime); // Compute how long it's been in this loop in ms. We will terminate
      // when the elapsed time is greater than the pulse width that we asked for.
       
        for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { // Loop (very quickly) over all pins
                 int val = sin(double(elapsedTimeMilliSecs)*0.0062832*double(modulationRateHz))*double(LEDamps[thisPinIndex])+double(LEDbaseLevel[thisPinIndex]);
                 // int val = sin( double(elapsedTimeMilliSecs)*0.0062832*double(modulationRateHz))*(double(LEDamps[thisPinIndex]))+LEDbaseLevel[thisPinIndex];
        
                      analogWrite(ledPins[thisPinIndex], val); // Write value to the pin
        } // Next pin
    } // end while loop;
    
    
    // Set everything to mean level  afterwards. 
      for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 
           analogWrite(ledPins[thisPinIndex], int(LEDbaseLevel[thisPinIndex]));   // To add in a quick black flicker
      }
     // delay(100);
      
    //  for (int thisPinIndex = 0; thisPinIndex < 5; thisPinIndex++) { 

        //            analogWrite(ledPins[thisPinIndex], LEDbaseLevel[thisPinIndex]);
    //  } // next pin to zero 
      

} // end function









