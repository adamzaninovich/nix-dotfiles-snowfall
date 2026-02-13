{ channels, ... }:

final: prev: {
  unstable = channels.unstable;

  # gh 2.72 from nixos-25.05 fails with "Projects (classic) is being deprecated"
  # on `gh pr view` — fixed in newer versions
  inherit (channels.unstable) gh;
}
