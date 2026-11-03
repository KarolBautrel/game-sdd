# World slice006: Ravenford trading post

Owner: ../006_town_trade.md. Stage17.

| ID | Acceptance | Proof |
| --- | --- | --- |
| W17-01 | Unique known offers, integral prices above resale, invalid data rejected | Python/schema and town_trade_tests |
| W17-02 | Buy/sell exactly one at trusted price, no auto-equip or unrelated mutations, no buy/sell profit | town_trade_tests |
| W17-03 | Quest/legacy/missing/assigned item, insufficient funds, remote/active/pending/unloaded gates | same suite |
| W17-04 | Spare assigned-item sale preserves gear; failed writes roll back; restart retains exact totals | same suite |
| W17-05 | Actual town Open/selection/Buy/Sell/Back controls and packaged resources | same suite/extended export probe |
| W17-06 | Visible trade/equip/restart and rejection/readability | live L17-01/02 NOT_RUN |
