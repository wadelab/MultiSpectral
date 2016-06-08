/*
This code does one thing: It reads 7 values from the serial port at a time, then uses those values as amplitudes 
for a flickering pulse on the LEDs. The pulse lasts 1 second
 */

// this constant won't change:
const int ledPins[] = { 2, 3,4,5,6,7,8 };       // the pin that the LED is attached to

// Variables will change:
double startTime;
float modulationRateHz[] = {2,2,2,2,2,2,2}; // Flicker rate of the LEDs when they're on
int LEDamps[] = {0,255,0,255,0,255,0};
int LEDactive[] = {1,1,1,1,1,1,1};
float pulseDuration = 1;
float elapsedTimeSecs =0;
char incomingByte;   // for incoming serial data

void setup() {

  
  // initialize serial communication:
  Serial.begin(9600);
 
   startTime=millis();
     for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { 
         analogWriteResolution(12);

         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         analogWrite(ledPins[thisPinIndex], 2048);   
         delay(100);
  } // Next pin
} // end of setup


void loop() {
// This runs forever
  int bytesReadFromSerial  =0;
  
  
  while (bytesReadFromSerial<7) {
    if (Serial.available() > 0) {
    bytesReadFromSerial++;
    LEDamps[bytesReadFromSerial] = Serial.read();
        } // End if statement - look for another byte
   }  // End while statement - we will stop when we have 7 bytes
   Serial.flush();
   bytesReadFromSerial  =0;
   
                /* We now have 7 amplitudes - one for each of the LEDs. We will modulate them with these amplitudes
                for one second (or pulseDuration) - then go back to the start of the loop
                */
              
       // Here we loop for one second
     startTime=millis();
     analogWriteResolution(12);

    while (elapsedTimeSecs < pulseDuration) {
       elapsedTimeSecs=(millis()-startTime)/1000.0; // Compute how long it's been in this loop in seconds. We will terminate
      // when the elapsed time is greater than the pulse width that we asked for.
       
        for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { 
            int val = (sin(elapsedTimeSecs*2.0*3.1415927*modulationRateHz[thisPinIndex])*(LEDamps[thisPinIndex]/2));
      
            analogWrite(ledPins[thisPinIndex], val*2);
        } // Next pin
    } // end while loop;
      for (int thisPinIndex = 0; thisPinIndex < 7; thisPinIndex++) { 
                    analogWrite(ledPins[thisPinIndex], 0);
      }
      

} // end function









