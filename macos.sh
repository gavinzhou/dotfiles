#!/usr/bin/env bash

# Map Caps Lock key to Left Control key
# https://developer.apple.com/library/content/technotes/tn2450/_index.html
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'

defaults -currentHost write -g com.apple.mouse.tapBehavior 1

