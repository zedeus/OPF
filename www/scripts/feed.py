import RPi.GPIO as GPIO
import time
import os.path
import sys

frequencyHertz = 100
msPerCycle = 1000 / frequencyHertz

leftPosition = 2
rightPosition = 2 

positionList = [leftPosition, rightPosition]

tmpfile = "/var/www/html/data/servo_run"

def run_cycle(i):
    GPIO.setmode(GPIO.BOARD)
    GPIO.setup(7, GPIO.OUT)
    pwm = GPIO.PWM(7, frequencyHertz)
    for i in range(i):
        for position in positionList:
            dutyCyclePercentage = position * 100 / msPerCycle
            pwm.start(dutyCyclePercentage)
            time.sleep(2)
    pwm.stop()
    GPIO.cleanup()

def write_file(file, n):
    f = open(file, 'w')
    f.write(str(n))
    f.close()

if (os.path.isfile(tmpfile)):
    print("File found")
    f = open(tmpfile, 'r+')
    if (f.read() == "0"):
        print("File contains 0, writing 1 and running cycle")
        f.write("1")
        f.close()
        run_cycle(2)
        print("Cycle done, writing 0")
        write_file(tmpfile, "0")
    else:
        print("File contains 1, stopping script")
        f.close()
else:
    print("File did not exist, writing 1 and starting cycle")
    write_file(tmpfile, "1")
    run_cycle(2)
    print("Cycle done, writing 0")
    write_file(tmpfile, "0")