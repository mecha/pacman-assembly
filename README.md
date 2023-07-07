# A Pacman Clone in Assembly

The title says it all.

A simple terminal clone of the classic Pacman game written in NASM assembly for x86_64. More specifically, Linux x86_64. Might work on Windows. Maybe. Don't count on it.

I'd also like to apologize to the assembly warriors for my (probably) terrible assembly.

## Todo

- [x] Win condition
- [x] Main menu
- [X] Enemies
- [X] Lives
- [X] Lose condition
- [ ] Powerup & eat enemies
- [ ] Fruit 🍒
- [ ] Sounds, question mark?

# Usage

Build with `make`:

```
make
```

This will build the binary in `.build/main`.

Alternatively, you can build and run in a single command:

```
make run
```

# Controls

| Key | Action |
| --- | ------ |
| ⇧   | Up     |
| ⇩   | Down   |
| ⇦   | Left   |
| ⇨   | Right  |
| p   | Pause  |
| q   | Quit   |

**Tip**: You can queue up to one ⇧⇩⇦⇨ move and Pacman will make that move as soon as it becomes possible.

# The level file

The level is loaded from the `level.dat` plain text file.

The file should contain a 44x31 character grid. You can probably decipher what the character represent by comparing the file to the rendered game, but here's a complete reference for convenience:

| Character | Tile            |
| --------- | --------------- |
| a         | ╔ [wall]        |
| b         | ╗ [wall]        |
| c         | ╚ [wall]        |
| d         | ╝ [wall]        |
| e         | ║ [wall]        |
| f         | ═ [wall]        |
| g         | ┌ [wall]        |
| h         | ┐ [wall]        |
| i         | └ [wall]        |
| j         | ┘ [wall]        |
| k         | │ [wall]        |
| l         | ─ [wall]        |
| m         | [out of bounds] |
| .         | ⋅ [pellet]      |
| ,         | ● [power up]    |
| z         | [end]           |

It's important to include a `z` at the end. This is required because I was lazy. Just include it, alright?

Any gaps in the top, bottom, left, and right edges of the level will function as a warp tunnel, teleporting Pacman to the other edge of the screen.

# Cheater!

Yes yes, I used some C code.

I couldn't figure out what how to control the terminal mode from assembly, so I resorted to good old `termios` in C. And while I'm adding some C code, I decided to throw in `atexit` in there as well.

If you know how to enable the terminal's raw mode in assembly without `termios`, feel free to submit a pull request 🙂.

# License

This project is [licensed](./LICENSE) under the GPL-3.0 license.
