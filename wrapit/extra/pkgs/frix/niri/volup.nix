{ writers }:
writers.writeBashBin "pipeWire-volup" ''
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+
  fyi -t 1000 $(wpctl get-volume @DEFAULT_AUDIO_SINK@)
''
