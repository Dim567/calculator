# Simple CLI calculator

This is a simple calculator written in Zig programming language, made as a learning project.
It allows to perform +, -, *, / operations and grouping with brackets.

## Run in dev mode

```bash
<project_directory>$ zig run ./src/main.zig
```

## Build and run

1. Build executable
```bash
<project_directory>$ zig build
```

2. Run executable

```bash
<project_directory>$ ./zig-out/bin/calculator
```

## Test

```bash
<project_directory>$ zig test ./src/main.zig
```

## Interface

### To calculate: 
 1. Type expression and put `=` at the end
 2. Press `Enter`

### To exit:
 1. Type `exit`
 2. Press `Enter`
