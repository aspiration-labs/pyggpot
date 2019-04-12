package main

import (
	"flag"
	"fmt"
	"github.com/aspiration-labs/pyggpot/internal/models"
	"log"
	"net/http"
	"os"

	"github.com/aspiration-labs/pyggpot/internal/hooks"
	"github.com/aspiration-labs/pyggpot/internal/providers/coin"
	"github.com/aspiration-labs/pyggpot/internal/providers/pot"
	"github.com/aspiration-labs/pyggpot/rpc/proto/coin"
	"github.com/aspiration-labs/pyggpot/rpc/proto/pot"
	_ "github.com/aspiration-labs/pyggpot/swaggerui-statik/statik"
	"github.com/gorilla/mux"
	"github.com/rakyll/statik/fs"
	"github.com/xo/dburl"
)

var flagVerbose = flag.Bool("v", false, "verbose")
var flagDB = flag.String("url", "file:database.sqlite3?_loc=auto&_foreign_keys=1", "database url")

func main() {

	flag.Parse()
	if *flagVerbose {
		models.XOLog = func(s string, p ...interface{}) {
			fmt.Printf("QUERY: %s\n  VAL: %v\n", s, p)
		}
	}

	db, err := dburl.Open(*flagDB)
	if err != nil {
		log.Fatal(err)
	}

	router := mux.NewRouter().StrictSlash(true)

	statikFS, err := fs.New()
	if err != nil {
		panic(err)
	}
	staticServer := http.FileServer(statikFS)
	router.PathPrefix("/swaggerui/").Handler(http.StripPrefix("/swaggerui/", staticServer))

	hook := hooks.LoggingHooks(os.Stderr)
	potProvider := pot_provider.New(db)
	potServer := pot_service.NewPotServer(potProvider, hook)
	router.PathPrefix(pot_service.PotPathPrefix).Handler(potServer)
	coinProvider := coin_provider.New(db)
	coinServer := coin_service.NewCoinServer(coinProvider, hook)
	router.PathPrefix(coin_service.CoinPathPrefix).Handler(coinServer)
	log.Fatal(http.ListenAndServe(":8080", router))
}
