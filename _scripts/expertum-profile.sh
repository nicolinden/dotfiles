#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Expertum Profile
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName Browser

# Documentation:
# @raycast.description Opens chrome private profile
# @raycast.author Nico van der Linden

open -na "Google Chrome" --args --profile-directory="Profile 1"