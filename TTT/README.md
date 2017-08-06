# README

## Responsibilities

### Classes

- *Board:* records, evaluates and displays TTT positions.
- *Player:* chooses moves on a TTT board. There are two subclasses of Player: *Human* and *Computer*.
- *Human:* choses moves according to user input.
- *Computer:* chooses moves based on "AI skill level" (dumb/intermediate/optimal).
- *Schedule:* determines who is to move.
- *ScoreKeeper:* keep tracks of round wins and match wins.
- *Match:* orchestrates the above-mentioned classes, managing the main game loop.
- *Settings:* stores user-customizable aspects of the game.
- *Game:* kicks off match based on settings.

### Modules

- *MessageToUser:* display text to user.
- *GetUserInput:* obtain validated user input.
