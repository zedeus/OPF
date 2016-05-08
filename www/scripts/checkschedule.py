import time 

current_time = time.strftime("%I:%M %p")

for line in open("/var/www/html/data/schedule", 'r').readlines():
    if line.rstrip() == current_time.rstrip():
        execfile("/var/www/html/scripts/feed.py")