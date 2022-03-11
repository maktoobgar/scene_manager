#!env/bin/python
# Install hooks

import os
import sys

text = "\thooksPath = .githooks"
husky = "hooksPath = .husky"

if not os.path.exists(".git"):
    print("no .git folder found")
    sys.exit(0)

f = open(".git/config", "r")
lines = f.readlines()
lines_string = ""
for line in lines:
    # adding config in core
    if line.strip() == "[core]":
        lines_string = line + text + "\n"
        continue
    # removing previous using husky tool
    if line.strip() != husky:
        lines_string += line
    # if configuration happened before, quit
    if line.strip().find(text.strip()) != -1:
        print("configurations happened before")
        sys.exit(0)
f.close()

f = open(".git/config", "w")
f.write(lines_string + "\n")
f.close()

print("git hooks activated")