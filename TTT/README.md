# README

## Responsibilities

### Classes

- *Board:* records, evaluates and displays TTT positions.
- *Player:* chooses moves on TTT board, based on a player's color (and, in the case of a computer player, based on skill level).
- There are two subclasses of Player: *Human* and *Computer*.
- *Schedule:* determines who is to move.
- *Score_keeper:* keep tracks of round wins and match wins.
- *Match:* orchestrates the above-mentioned classes, managing the main game loop.
- *Settings:* stores user-customizable aspects.
- *Game:* kicks off match based on settings.

### Modules

- *MessageToUser:* display text to user.
- *GetUserInput:* obtain validated user input.
