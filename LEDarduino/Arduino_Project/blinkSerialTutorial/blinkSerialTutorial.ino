/*
  This code is a simple example of how to get the Ardunio talking to another computer over the serial interface.
  You run this code on the Arduino.
  It sits and listens to the serial port. When a number ('1','2','3' etc comes in on the port it sets the LED on pin 13 high for that number of seconds
  
 
 */

// Variables will change:
char incomingByte;   // for incoming serial data

void setup() {
// This part of the code is run only once whenever the ardunio turns on or the reset button is pressed.
  
  // initialize serial communication:
  Serial.begin(9600);
 
 // Set all output pins to 'OUTPUT' mode. In this example, there's only 1 pin
 // which is 13. On all ardunio boards this is already connected to an onboard orange LED.
         pinMode(13, OUTPUT);

         // turn the pin off:
         digitalWrite(13, LOW);   
    
} // end of setup


void loop() {
// This runs forever
  if (Serial.available() > 0) { // Check to see if anything is there on the serial port.
                // read the incoming byte:
                incomingByte = Serial.read();
                unsigned long p=(incomingByte-'0');
                if (p<0) p=0;
                if (p>9) p=9;
                
                Serial.println(p,'DEC');
                p=p*100;
                
                 // turn the pin on:
                 digitalWrite(13, HIGH);   
                 delay(p); // Wait for this many milliseconds
                    
                 // turn the pin off:
                 digitalWrite(13, LOW); 
             

  } // End if statement and loop again.
                
 

}









