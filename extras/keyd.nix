# NixOS module · tap Super alone = leader. keyd turns a lone Super tap (released < 200 ms, no other
# key) into F13; Hyprland sees keysym XF86Tools → bind it to apgo.open(). Hold Super = Super as before.
# Check live: `sudo keyd monitor`.
{ ... }:
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        leftmeta = "overloadt2(meta, f13, 200)";
      };
    };
  };
}
