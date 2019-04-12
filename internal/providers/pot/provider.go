package pot_provider

import (
	"context"
	"database/sql"
	"github.com/aspiration-labs/pyggpot/internal/models"
	"github.com/aspiration-labs/pyggpot/rpc/proto/pot"
	"github.com/golang/protobuf/ptypes/timestamp"
	"github.com/twitchtv/twirp"
	"github.com/xo/xoutil"
	"time"
)

type potServer struct{
	DB *sql.DB
}

func New(db *sql.DB) *potServer {
	return &potServer{
		DB: db,
	}
}

func (s *potServer) ViewPot(ctx context.Context, request *pot_service.ViewPotRequest) (*pot_service.PotResponse, error) {
	if err := request.Validate(); err != nil {
		return nil, twirp.InvalidArgumentError(err.Error(), "")
	}
	pot, err := models.PotByID(s.DB, request.PotId)
	if err != nil {
		return nil, twirp.NotFoundError(err.Error())
	}
	return &pot_service.PotResponse{
		PotId: pot.ID,
		PotName: pot.PotName,
		MaxCoins: pot.MaxCoins,
		CreateTime: &timestamp.Timestamp{Seconds:pot.CreateTime.Unix(), Nanos: int32(pot.CreateTime.Nanosecond())},
	}, nil}

func (s *potServer) ListPots(ctx context.Context, request *pot_service.ListPotsRequest) (*pot_service.PotListResponse, error) {
	if request.Limit == 0 {
		request.Limit = 25
	}
	if err := request.Validate(); err != nil {
		return nil, twirp.InvalidArgumentError(err.Error(), "")
	}

	potCount, err := models.PotCount(s.DB)
	if err != nil {
		return nil, twirp.InternalError(err.Error())
	}
	offset := (request.Page - 1) * request.Limit
	pots, err := models.PotsPagedsByOffsetLimit(s.DB, int(offset), int(request.Limit))
	if err != nil {
		return nil, twirp.NotFoundError(err.Error())
	}

	potResult := []*pot_service.PotResponse{}
	for _, pot := range pots {
		pot := pot_service.PotResponse{
			PotId: pot.ID,
			PotName: pot.PotName,
			MaxCoins: pot.MaxCoins,
			CreateTime: &timestamp.Timestamp{Seconds:pot.CreateTime.Unix(), Nanos: int32(pot.CreateTime.Nanosecond())},
		}
		potResult = append(potResult, &pot)
	}
	potList := pot_service.PotListResponse{
		TotalPotCount: potCount,
		Request: request,
		Pots: potResult,
	}

	return &potList, nil
}

func (s *potServer) ViewPotByName(context.Context, *pot_service.ViewPotByNameRequest) (*pot_service.PotResponse, error) {
	panic("implement me")
}

func (s *potServer) CreatePot(ctx context.Context, request *pot_service.CreatePotRequest) (*pot_service.PotResponse, error) {
	if err := request.Validate(); err != nil {
		return nil, twirp.InvalidArgumentError(err.Error(), "")
	}
	pot := models.Pot{
		PotName:    request.PotName,
		MaxCoins:   request.MaxCoins,
		CreateTime: xoutil.SqTime{time.Now()},
	}
	if err := pot.Save(s.DB); err != nil {
		return nil, twirp.InvalidArgumentError(err.Error(), "")
	}
	return &pot_service.PotResponse{
		PotId: pot.ID,
		PotName: pot.PotName,
		MaxCoins: pot.MaxCoins,
		CreateTime: &timestamp.Timestamp{Seconds:pot.CreateTime.Unix(), Nanos: int32(pot.CreateTime.Nanosecond())},
	}, nil
}