# OPF - Open Pet Feeder Project

## What is OPF?

OPF is a project built to make automated pet-feeding easy. It's designed with a RaspberryPi (RPi), the official RPi camera module (PiCam), and a servomoter. It features a _quick feed_ button and a time schedule, which is checked every 10 minutes by a cronjob:

`*/10 * * * * python /var/www/html/scripts/checkschedule.py`

The web server has been optimized for both PCs and mobile devices using responsive design. It's based on the [RPi_Cam_Web_Interface](http://elinux.org/RPi-Cam-Web-Interface) project, which serves as a great out-of-the-box configuration for setting up an Apache server, that streams the PiCam using RaspiMJPEG.

## Screenshots

#### On a 1920x1080 monitor
![1080p resolution](http://i.imgur.com/yJVT65S.png)

#### On a OnePlus One (mobile, 1080x1920)
<a href="http://i.imgur.com/5CXr7BK.png"><img src="http://i.imgur.com/5CXr7BK.png" height="800" ></a>
