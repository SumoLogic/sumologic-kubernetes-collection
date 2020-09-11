#/usr/bin/env bash

targets=$(cat /sumologic/vagrant/Makefile | grep -oE '^\S*\:' | sed 's/\:$//g')
complete -W "${targets}" sumo-make
