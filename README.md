### mcrcon-d

A simple Minecraft RCON client written in D.

#### Building

This project depends on `dmd`, GNU readline, and optionally `dub`.

Using dub:

```
$ dub build
```

Using dmd:

```
$ dmd source/app.d source/mcrcon.d source/rl.d -L-lreadline
```

#### Usage

`mcrcon-d [-H host] [-P port] -p password [-h] [COMMANDS]`

Options:
```
-H     --host           Server address, default: localhost
-P     --port           Port, default: 25575
-p --password Required: RCON Password
-h     --help           This help information.
```

If no commands are provided, the program runs under an interactive RCON command shell. Otherwise the program runs all commands in sequence, and exits.

#### License

This project is licensed under the GNU GPL version 3 or any later version. See [LICENSE](./LICENSE) for details.

#### TODO:

Non-exhaustive list of possible improvements:

- [ ] Allow passing option as environment variables.
- [ ] Improve error handling.
- [ ] Build mcrcon as a library.