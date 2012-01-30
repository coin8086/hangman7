#!/usr/bin/env bash

export hangman_dict=../words.txt
./RandomWords 1000 | ./HangmanGame
