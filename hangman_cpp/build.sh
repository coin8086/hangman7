#!/usr/bin/env bash

g++ -O2 -DNDEBUG -o HangmanGame HangmanGame.cpp MyGuessingStrategy.cpp Main.cpp
g++ -O2 -DNDEBUG -o RandomWords RandomWords.cpp
