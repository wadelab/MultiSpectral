/*
This code does one thing: It reads 7 values from the serial port at a time, then uses those values as amplitudes 
for a flickering pulse on the LEDs. The pulse lasts 3 second
The name has a number in it _012715_1 that should match some matlab code somewhere...
TODO : Add noise (possibly) to increase thresholds and mask stim onset. Or allow a Gaussian temporal envelope.

 */
 
 
// this constant won't change:
const int ledPins[] = {8,9,10,11,12};       // the pin that the LED is attached to

// Variables will change:
unsigned long startTime;
byte modulationRateHz16Bit[2]; // Flicker rate of the LEDs when they're on - default 0, overridden when serial port receives the value
 int LEDamps[] = {0,0,0,0,0}; // How much each LED flickers (from 0 to 256) about the baseline. Obviously if the baseline is 128, the flicker amplitude must be no more than 128.
byte LEDampSign[] = {0,0,0,0,0}; // indicate the sign of the amp, here 0 is positive and 1 is a negative
 int LEDbaseLevel[] = {0,0,0,0,0}; //{32,144,192,128}; // These are the baseline levels of the LEDs. They are set through Matlab inputs so these values here are just examples
byte LEDampInputArray[10]; // Explicitly set to the number of LEDs * 2
byte LEDampBaseInputArray[10]; // Explicitly set to the number of LEDs * 2
double modulationRateHz;
long pulseDuration = 750; // How long each pulse lasts in ms
long elapsedTimeMilliSecs = 0; 
int halfAmp = 2048; // Half the maximum amplitude. 
int nPins = 5;
byte LEDscaling[5]; //this is the relative scaling of each LED based on the differences in brightness.  Use this to scale the noise N.B. update this so input
 
void setup() {

   analogWriteResolution(12); // Because this is the Due and we want high precision

  // initialize serial communication:
      Serial.begin(9600);
     for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 

         pinMode(ledPins[thisPinIndex], OUTPUT);

         // turn the pin off:
         analogWrite(ledPins[thisPinIndex], halfAmp);   
         delay(100); // To make it look fancy
         
         analogWrite(ledPins[thisPinIndex], LEDbaseLevel[thisPinIndex]);   
         
  } // Next pin
  delay(1000);
} // end of setup


void loop() {
// This runs forever  
  int bytesRead=0; // Have we read from the serial port recently? 0 for no, 1 for yes
  
  Serial.flush(); // Not sure if we need this but it can't hurt

  while (bytesRead<1) { // Keep looping until there's something available to read
  
  // In the 16 bit version of the code, we read two bytes per LED. When matlab sends 16 bit values, it sends low, then high byte.
  // When we read them, we read the low byte first, then add this to a bit-shifted (<<8) version of the next byte.
  // Initially we read everything into byte arrays, then do the maths at the end.
  
      if (Serial.available() > 0) {
          Serial.readBytes(LEDampInputArray,nPins*2); // First nPins bytes are the modulation amps. We read in 2 bytes per pin
          Serial.readBytes(LEDampSign,nPins); // next, nPins indicate the sign of the amps. 1 byte per pin
          Serial.readBytes(LEDampBaseInputArray,nPins*2); // following 2 bytes per nPins bytes are the baselines.
          Serial.readBytes(modulationRateHz16Bit,2); // 2 bytes are the frequency of the flicker in Hz multiplied by 256. We do this to allow fractional flicker rates.
          Serial.readBytes(LEDscaling,nPins); //the scaling needed for each LED
          
          
          // We've read in 2 bytes per output pin (these correspond to LEDs on the output) . We convert these into proper signed ints by assuming that the first
          // byte is the low end and the second byte is the high end. So we can construct a 16 bit number as SB*256+FB more or less
          // We have to account for the highest bit of the high byte as this will contain a sign (0 for positive, 1 for -ve)
          // . Note that we use <<8 
          // (shift left by 8 bits) to multiply by 256
          // On the Due the unsigned ints are 4 bytes long
          
          for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { // Loop (very quickly) over all pins
              LEDamps[thisPinIndex]=((int(LEDampInputArray[thisPinIndex*2]))+((int(127 & LEDampInputArray[thisPinIndex*2+1]))<<8));

              if (LEDampSign[thisPinIndex] = 1) {
               LEDamps[thisPinIndex]=-LEDamps[thisPinIndex]; // check if the amp value needs to be negative (1 in the LEDampSign)
                
              }
             
              LEDbaseLevel[thisPinIndex]=(int(LEDampBaseInputArray[thisPinIndex*2]))+((int(LEDampBaseInputArray[thisPinIndex*2+1]))<<8);
          } // next pin data

         
          modulationRateHz= double(int(modulationRateHz16Bit[0])+(int(modulationRateHz16Bit[1]))<<8)/256;
          

          bytesRead=1; // Tell the loop we've read something - go ahead and run the flicker that's been asked for
      }  // End while statement - we will stop when we have 7 pins worth of inputs
  }
  
  
  Serial.flush(); // Not sure if we need this but it can't hurt
   
                /* We now have amplitudes - one for each of the LEDs. We will modulate them with these amplitudes
                for one second (or pulseDuration) - then go back to the start of the loop
                */
   for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 
       analogWrite(ledPins[thisPinIndex], 0);   // To add in a quick black pulse and reset the LEDs. Mostly you do this as a cue to the subject so they know something's coming.
   }
              
   delay(100);
            
    // Set everything to mean level for 100ms before stim starts. 
    for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 
           analogWrite(ledPins[thisPinIndex], int(LEDbaseLevel[thisPinIndex]));   // To reset to mean level
    }         
    
    delay(100);
    
       // Here we loop for one pulseDuration
   startTime=millis(); // Log the current time in ms
   elapsedTimeMilliSecs=0; // This will count up until it reaches the pulseDuration

   while (elapsedTimeMilliSecs < pulseDuration) { // Keep checking to see how long we've been in this loop (in ms)
       elapsedTimeMilliSecs=(millis()-startTime); // Compute how long it's been in this loop in ms. We will terminate
      // when the elapsed time is greater than the pulse width that we asked for.
       long rNum = random(-10,10); //this number will get scaled for each LED based on the background level for each LED
       
        for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { // Loop (very quickly) over all pins
                 int val = sin(double(elapsedTimeMilliSecs)*0.0062832*double(modulationRateHz))*double(LEDamps[thisPinIndex])+double(LEDbaseLevel[thisPinIndex])+(rNum*(LEDscaling[thisPinIndex]*2));
                 // int val = sin( double(elapsedTimeMilliSecs)*0.0062832*double(modulationRateHz))*(double(LEDamps[thisPinIndex]))+LEDbaseLevel[thisPinIndex];
                      
                      analogWrite(ledPins[thisPinIndex], val); // Write value to the pin. These are ints... so in the case of a  12 bit value they are 0-4095. This is taken care of on the matlab side
               // So, to be clear. To get a 10% modulation on a pin about the half max point, matlab will send a base level of 2048 as a 2-byte number (low end first: 0, 8)
               // and a modulation of 205 (205,0). The error here is about 1 part in 1000.
        } // Next pin
    } // end while loop;
    
    
    // Set everything to mean level  afterwards. 
    for (int thisPinIndex = 0; thisPinIndex < nPins; thisPinIndex++) { 
           analogWrite(ledPins[thisPinIndex], int(LEDbaseLevel[thisPinIndex]));   // To reset to mean level
    }
     
      

} // end function









