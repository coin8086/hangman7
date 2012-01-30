#!/usr/bin/env bash

export hangman_dict=../words.txt
java RandomWords 1000 | java Main
