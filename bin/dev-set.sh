#!/usr/bin/env bash

bin/deploy.sh dev localhost
SKIP_COMPILE=true bin/export.sh
