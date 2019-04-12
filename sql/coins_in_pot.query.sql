SELECT c.id, c.denomination, c.coin_count
FROM coin c
WHERE c.pot_id = %%pot_id int%%
