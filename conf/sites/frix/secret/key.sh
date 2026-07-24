#!/usr/bin/env bash

mkdir -p /var/lib/agenix
touch /var/lib/agenix/key
age -d ./key.age > /var/lib/agenix/key

