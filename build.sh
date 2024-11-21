#!/bin/bash

# Build the project using ncc
ncc build index.js --license licenses.txt

# Commit the changes to GitHub
git add .
git commit -m "Build and update v1 tag"

# Update the v1 tag both locally and remotely
git push origin --delete v1
git tag -d v1
git tag -a -m 'v1' v1
git push --follow-tags