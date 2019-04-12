package coin_provider

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/aspiration-labs/pyggpot/internal/models"
	"github.com/aspiration-labs/pyggpot/rpc/proto/coin"
	"github.com/twitchtv/twirp"
)

type coinServer struct{
	DB *sql.DB
}

func New(db *sql.DB) *coinServer {
	return &coinServer{
		DB: db,
	}
}

func (s *coinServer) AddCoins(ctx context.Context, request *coin_service.AddCoinsRequest) (*coin_service.CoinsListResponse, error) {
	if err := request.Validate(); err != nil {
		return nil, twirp.InvalidArgumentError(err.Error(), "")
	}

	tx, err := s.DB.Begin()
	if err != nil {
		return nil, twirp.InternalError(err.Error())
	}
	for _, coin := range request.Coins {
		fmt.Println(coin)
		newCoin := models.Coin{
			PotID: request.PotId,
			Denomination: int32(coin.Kind),
			CoinCount: coin.Count,
		}
		err = newCoin.Save(tx)
		if err != nil {
			return nil, twirp.InvalidArgumentError(err.Error(), "")
		}
	}
	err = tx.Commit()
	if err != nil {
		return nil, twirp.NotFoundError(err.Error())
	}

	return &coin_service.CoinsListResponse{
		Coins: request.Coins,
	}, nil
}

func (s *coinServer) RemoveCoins(context.Context, *coin_service.RemoveCoinsRequest) (*coin_service.CoinsListResponse, error) {
	panic("implement me")
}