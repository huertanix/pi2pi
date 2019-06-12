#!/bin/sh

echo "Beginning photo sync..."

#if [ "$(hostname)"=="rpa.local" ]; then
#echo "$(hostname -s)"
if [ "$(hostname -s)" = "rpa" ]; then
  recipient_host="rpb.local"
  #recipient_host="10.0.0.49" #rpb
  #recipient_host="rpb"
  echo "Sending photos to "$recipient_host"..."
else
  recipient_host="rpa.local"
  #recipient_host="10.0.0.1" #rpa
  #recipient_host="rpa"
  echo "Sending photos to "$recipient_host"..."
fi

usb_drive_name="$(ls /media/pi/ | head -n 1)"
#usb_drive_name_escaped="(command printf '%q' $usb_drive_name)"
#usb_drive_name_escaped=${$usb_drive_name// /\ }
#usb_drive_name_escaped=${usb_drive_name// /_}

echo "Using USB drive:" $usb_drive_name

sender_path=/media/pi/$usb_drive_name/sending

recipient_path=/media/pi/$usb_drive_name/receiving

echo "Sending files in:" $sender_path
echo "Sending files to:" $recipient_host:$recipient_path

rsync --progress -a --recursive --ignore-times $sender_path/. pi@$recipient_host:$recipient_path

echo "Fin."
