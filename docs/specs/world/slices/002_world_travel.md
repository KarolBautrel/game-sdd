# World slice002: travel

Owner: ../002_world_travel.md.

| ID | Scenario | Expected |
| --- | --- | --- |
| W13-01 | Quote and travel both road directions | Exact food/hours/location/sequence; return reserve retained; self replay rejected. |
| W13-02 | Unknown route, insufficient food/reserve, active run, write failure | Atomic rejection; memory/file unchanged. |
| W13-03 | Load valid legacy v1, then transact/reload | Progress preserved; no load-time rewrite; v2 world state durable. |
| W13-04 | Remote market/inn/preparation and packing | Location gates and return reserve enforced by service, reflected by UI. |
| W13-05 | Actual map travel/clock/reserve and restart | live L13-01/02, NOT_RUN. |

Automated: world_travel_tests.gd, campaign_session_tests.gd, world_town_tests.gd
and complete verifier. Headless checks do not accept W13-05.
