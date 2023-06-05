#!/bin/bash

d=$1

dcm=$(find $d -name *0001.dcm | head -n 1)

echo $dcm

dcminfo "$dcm"