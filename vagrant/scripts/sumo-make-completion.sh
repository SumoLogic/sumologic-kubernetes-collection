#!/usr/bin/env bash

targets=$(grep -oE '^\S*\:' /sumologic/vagrant/Makefile | sed 's/\:$//g')
complete -W "${targets}" sumo-make
