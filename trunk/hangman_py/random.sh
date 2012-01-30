#!/usr/bin/env bash

export hangman_dict=../words.txt
python RandomWords.py 1000 | python Main.py
