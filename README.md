<h1 align="center">Team Fortress 2 - Item Management Plugins</h1>

A 2024 refresh rewrite for plugins that manage player cosmetics & weapons, along with a provisory **VIP system** menu for servers to use.

## TOS & `m_bValidatedAttachedEntity`

Some months ago I started developing private plugins for communities that modify items for the game. It **IS AGAINST TOS**, and I know this can't be released on **AlliedModders** because of such, but because **VALVe** doesn't care for their game and it's been 7 years since a token ban has been issued I'll be releasing these public.

As [404](https://github.com/404UNFca) said once:
```
It technically is against the TOS, and using something like it could have potentially gotten your server blacklisted about 8-9 years ago. Nowadays, not so much. Many community servers in existence are using this system.

For example, Skial uses it for their "!items" system that allows you to equip any weapon or cosmetic you want (even rare ones like the Wiki Cap, Top Notch, Golden Wrench, Golden Frying Pan, etc) and they're visible to other players. What has changed in the past 8-9 years is that Valve is now more focused on CS:GO and Half Life: Alyx.

TF2 servers have not suffered any GLST token bans in many years. Even CS:GO servers, which were frequently hit by GLST token bans for using fake knife/gun/etc skin plugins, have slowly over time stopped being hit by GLST token bans. It seems Valve has either lightened up on former community "restrictions", or they're too busy with HL:A to notice. lmao nevermind, seems they just banned the GLST tokens of someone in our community who was generating them en masse. Be careful if you choose to use this fucker as Valve could rear their heads towards Team Fortress 2 next. Especially be careful if you're a group like Skial that abuses this netprop.

Basically, by using this plugin, you are acknowledging that there is still the possibility that Valve could come around one day and blacklist your server. Don't blame me if such a thing happens either.
```
[source](https://github.com/NiagaraDryGuy/TF2ServersidePlayerAttachmentFixer/blob/90c2a2f41cd8b4fc872de59d05114913064066cd/README.md#frequently-asked-question-yes-singular)

I might make some other releases if people want things fixed or whatever. I just release them because keeping them private is worthless, they're already everywhere and even some other devs have made their own versions of this public as well.
Feel free to use these plugins wherever you want.

**This plugin makes use of the ``m_bValidatedAttachedEntity`` networked property, which bypasses the restriction made by VALVe where fake items are invisible to others. Everyone on the server will be able to see your items with these plugins.**

## Requirements

The plugins depend on the following extensions/plugins to be installed on your server:
* [TF2Items (1.6.4-279)](https://forums.alliedmods.net/showthread.php?t=115100)
* [TF2Attributes](https://github.com/FlaminSarge/tf2attributes)
* [TFEconData](https://github.com/nosoop/SM-TFEconData)
* [SteamWorks](https://users.alliedmods.net/~kyles/builds/SteamWorks/)
* [SMJansson](https://forums.alliedmods.net/showthread.php?t=184604)

**Only for devs**: For compilation you require my custom includes provided in the repository, the includes from the dependencies mentioned above and the following includes as well:
* [MoreColors](https://forums.alliedmods.net/showthread.php?t=185016)

## Installation

**Read before asking or creating an issue**. You first need to install the requirements, for this read all the articles inside the [Requirements](https://github.com/punteroo/TF2-Item-Plugins#requirements) section (links) and install them independently following their tutorials, then head over to the [Releases](https://github.com/punteroo/TF2-Item-Plugins/releases) section in this repository and download the latest one.

To enable **preference saving** which is a feature that comes with the plugin pack, add this entry in your `addons/sourcemod/configs/databases.cfg` file for your server:
```
"tf2itemplugins_db"
{
    "driver"		"sqlite"
    "host"			"localhost"
    "database"		"tf2itemplugins_db"
    "user"			"root"
    "pass"			""
}
```

