# Continuous strategic motion

Stage79, user feedback2026-11-04. Preserve designer terrain revision9 byte for
byte; movement costs, base speed and fifteen-minute simulation ticks remain011.

Every strategic walk can return a transient ordered motion trace: exact points
on the travelled path plus spent movement budget. Terrain-boundary times use
actual weighted cost. Stationary arrivals hold their endpoint for the remaining
fraction. Traces never enter campaign/save schemas, consume resources or decide
gameplay; publish them only after a successful CampaignSession transaction.
Failed writes leave both committed state and the last published trace intact.
Exact start/end links may bypass their own cell center only when segment
validation proves no blocked/corner crossing and weighted cost does not rise.
Within-cell courses are direct; ordinary waypoint changes must not introduce
an unnecessary backward excursion to a cell center.

NPCs carry unused tick budget through ordinary route waypoints and endpoint
turnarounds. Patrol endpoint guards remain intentional two-hour rests. Bound the
waypoint loop to avoid zero-length/malformed-route hangs. Delivery/contact and
faction rules retain their existing ownership; no pause at each grid/road node.

The terrain validator accepts finite integral JSON numbers such as192.0, as
emitted by Godot's editor serializer, while rejecting fractional/nonfinite/bool
dimensions. Validation must never rewrite the user's semantic mask.

Proof: slice012, living_motion_tests.gd and existing living/session/navigation
suites. Motion timing is presented under presentation038.
