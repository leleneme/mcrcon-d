### mcrcon-d

A simple MCRCON client written in D.


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