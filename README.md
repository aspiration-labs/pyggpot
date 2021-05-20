# Pyggpot Microservice Sample

In case you're wondering: [Pyggpot](https://bahoukas.com/pygg-pots-to-piggy-banks/)

## Prereqs

- [Go 1.16](https://golang.org/doc/install). Go < 1.16 _probably_ won't work due to [this issue in xoutil](https://github.com/xo/xo/issues/242).

## Installation

- Clone repo

```$bash
git clone git@github.com:aspiration-labs/pyggpot.git
```

- Install modules and vendored tools

```$bash
make setup
```

- Create sqlite database

```$bash
make db
```

- Generate proto and model code

```$bash
make all
```

## Run

```$bash
go run cmd/server/main.go
```

## Play

Swagger site at [http://localhost:8080/swaggerui/](http://localhost:8080/swaggerui/)
