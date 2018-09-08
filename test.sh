#!/bin/bash
echo '' > /tmp/test
while true; do
	echo "howdy from stdout" >> /tmp/test;
	>&2 date;
	sleep 0.2;
done
