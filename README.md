# Pyggpot Microservice Sample
In case you're wondering: [Pyggpot](https://bahoukas.com/pygg-pots-to-piggy-banks/)

## Prereqs

- A [go modules](https://blog.golang.org/modules2019) compatible version of Golang, i.e., 1.11 or later.

## Installation

- Clone repo
```$bash
git clone git@github.com:aspiration-labs/pyggpot.git
```
- Install modules and vendored tools
```$bash
make setup
```
- Create empty sqlite database
```$bash
make resetdb
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