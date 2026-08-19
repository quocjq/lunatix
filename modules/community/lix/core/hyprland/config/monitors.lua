hl.monitor({
  output = "eDP-1",
  mode = "1920x1080@60",
  position = "auto",
  scale = "1.0",
})

hl.workspace_rule({
  workspace = "1",
  monitor = "eDP-1",
  default = true,
})
