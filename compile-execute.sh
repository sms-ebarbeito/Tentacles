#!/bin/bash

swift build 2>&1 | tail -5
pkill -f BuddyApp; sleep 0.5 && /Users/ebarbeito/Documents/third-party/notifications/.build/arm64-apple-macosx/debug/BuddyApp &

