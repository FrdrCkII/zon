{ writers }:
writers.writeBashBin "fcitx5-switch" ''
  if [ "$(fcitx5-remote --check 2>/dev/null)" = "0" ]; then
      fcitx5-remote -e
      fcitx5 -d
  else
      fcitx5-remote -t
  fi
''
