# Slice041: quicker tactical walking with planted stride

Owner presentation041, accepted022/024/025.
- Painted160px stride completes in1/1.18seconds; source clips/pixels remain intact.
- Same physical distance gives the same foot phase at30/60/144FPS, independent of
  path segmentation or repeated orders; root and frame share a tween sample.
- Ordinary preview/confirm preserves MP, endpoints, facing and input lock; reset
  cancels stale movement samples and clears phases. Idle/death stay correct.
- Retain native timing/frame samples and an actual ordinary control move before
  expanding to environment/terrain polish; no Debug Win is acceptance evidence.
