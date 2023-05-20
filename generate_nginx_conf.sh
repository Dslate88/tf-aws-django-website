#!/bin/bash
UPSTREAM_SERVER=$1
envsubst $UPSTREAM_SERVER < nginx.conf.template > nginx.conf
