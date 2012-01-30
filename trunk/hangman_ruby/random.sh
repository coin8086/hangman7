#!/usr/bin/env bash

export hangman_dict=../words.txt
ruby RandomWords.rb 1000 | ruby Main.rb
