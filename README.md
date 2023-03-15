# PRANG!

[![ContentDB](https://content.minetest.net/packages/luk3yx/prang/shields/downloads/)](https://content.minetest.net/packages/luk3yx/prang/)

An unofficial port of
[PRANG!](https://atomicshrimp.com/post/2020/01/10/Play-PRANG!), a 2D
arcade-style game, to Minetest.

![Screenshot](https://content.minetest.net/uploads/15b90a793d.png)

There are instructions on how to play inside the game. In short, you have to
collect food/potions and avoid enemies. You can get a powerup (umbrella) to be
able to destroy enemies, however obstacles are deadly while you have the
powerup.

Requires 5.4.0+ servers, however it should work with clients down to 5.0.0
(although it will send more HUD updates to clients older than 5.2.0).

On MT 5.6.0 and older, you may need to zoom out to be able to see the entire
game on smaller displays.

## Download

You can install PRANG! using Minetest's "browse online content" feature.

Alternatively, you can download a .zip or clone one of the two Git repositories:

 - [Download .zip](https://content.minetest.net/packages/luk3yx/prang/download/)
 - [GitHub](https://github.com/luk3yx/minetest-prang)
 - [GitLab](https://gitlab.com/luk3yx/minetest-prang)

## Public server

If you don't want to download PRANG!, Edgy1 hosts a public server. Note that
movement processing and rendering is done server-side so there may be lag
and/or glitching if you are far away from the server (which is currently in
Canada) or have a poor internet connection. See
https://edgy1.net/minetest/prang for more information.

## License

### Code

`formspec_ast`, `fs51`, `hud_fs`, and `prang` are all MIT.

### Media

The textures are CC BY-SA 4.0
[Atomic Shrimp(?)](https://atomicshrimp.com/post/2020/01/10/Play-PRANG%21), and
the music is CC BY-SA 3.0
[Ozzed](https://ozzed.net/music/dunes-at-night.shtml).

See [the LICENSE.md file](https://gitlab.com/luk3yx/minetest-prang/-/blob/main/mods/prang/LICENSE.md) for more information.

![Credits image](https://raw.githubusercontent.com/luk3yx/minetest-prang/main/mods/prang/textures/prang_credits_bg.jpg)
