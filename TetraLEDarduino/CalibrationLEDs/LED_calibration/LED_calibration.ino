// turn on only the specified LED to run calibration (using the Jaz)

void setup() {
  // put your setup code here, to run once:

const int LEDs[] = {8,9,10,11,12}; //the LED pins available
int nPins = 5;
int ledOff = 0;
int ledOn = 255; //testing intensity at different % duty cycle: 20%=51, 40%=102, 60%=153, 80%=204, 100%=255

int currentLEDon = 3; // specify which LED you want on

    for (int thisPin = 0; thisPin < nPins; thisPin++) {
        pinMode(LEDs[thisPin], OUTPUT);

        // turn each pin off
        analogWrite(LEDs[thisPin], ledOff);
        delay(100);
    } // next LED

  // turn on the specified LED
    analogWrite(LEDs[currentLEDon], ledOn);
  }


void loop() {
  // put your main code here, to run repeatedly:
 

}
