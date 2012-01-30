#!/usr/bin/env bash

export hangman_dict=../words.txt
node RandomWords.js 1000 | node Main.js
