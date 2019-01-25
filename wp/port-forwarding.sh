#!/bin/sh

AUTOSSH_POLL=600
AUTOSSH_GATETIME=30
export AUTOSSH_POLL AUTOSSH_GATETIME

autossh -M 20000 -R 8888:localhost:80 -R 2222:localhost:22 -R 3306:localhost:3306 iv77msk.ru


