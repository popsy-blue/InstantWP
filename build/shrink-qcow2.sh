#!/bin/bash

echo ----------------------------
echo    QEMU Shrink VM Script
echo ----------------------------
cd "${0%/*}"

read VM_VERSION < ./VM_VERSION.txt
VM_ROOT=../core/vm/
VM_FILE="$VM_VERSION".qcow2
VM_IN=$VM_ROOT/$VM_FILE
VM_OUT=$VM_ROOT/"$VM_VERSION".small.qcow2

qemu-img convert -O qcow2 -c $VM_IN $VM_OUT
