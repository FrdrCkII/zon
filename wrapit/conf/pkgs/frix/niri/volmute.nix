{ writers }:
writers.writeBashBin "pipeWire-mute" ''
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  fyi -t 1000 $(wpctl get-volume @DEFAULT_AUDIO_SINK@)
''
