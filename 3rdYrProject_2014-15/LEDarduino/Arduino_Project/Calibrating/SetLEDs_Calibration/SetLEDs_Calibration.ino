/* Turn only one LED on to run calibration of each LED. 
  Manually change which LED is on by having only one set to ledState2 at a time, with the rest on ledState1.
 */

// constants won't change. Used here to set a pin number :
const int ledPin1 =  2;      // the number of the LED pin
const int ledPin2 =  3;
const int ledPin3 =  4;
const int ledPin4 =  5;
const int ledPin5 =  6;
const int ledPin6 =  7;
const int ledPin7 =  8;

// Variables will change :
int ledState1 = LOW;             // ledState used to set the LED
int ledState2= HIGH;
// Generally, you shuould use "unsigned long" for variables that hold time
// The value will quickly become too large for an int to store
unsigned long previousMillis = 0;        // will store last time LED was updated

// constants won't change :
const long interval = 10000;           // interval at which to blink (milliseconds)

void setup() {
  // set the digital pin as output:
  pinMode(ledPin1, OUTPUT);
  pinMode(ledPin2, OUTPUT);
  pinMode(ledPin3, OUTPUT);
  pinMode(ledPin4, OUTPUT);
  pinMode(ledPin5, OUTPUT);
  pinMode(ledPin6, OUTPUT);
  pinMode(ledPin7, OUTPUT);
 
}

void loop()
{
  // here is where you'd put code that needs to be running all the time.

  // check to see if it's time to blink the LED; that is, if the
  // difference between the current time and last time you blinked
  // the LED is bigger than the interval at which you want to
  // blink the LED.
  unsigned long currentMillis = millis();
 
  if(currentMillis - previousMillis >= interval) {
    // save the last time you blinked the LED 
    previousMillis = currentMillis;   

    // set the LED with the ledState of the variable:
    digitalWrite(ledPin1, ledState2);
    digitalWrite(ledPin2, ledState1);
    digitalWrite(ledPin3, ledState1);
    digitalWrite(ledPin4, ledState1);
    digitalWrite(ledPin5, ledState1);
    digitalWrite(ledPin6, ledState1);
    digitalWrite(ledPin7, ledState1);
  }
}

