# vRP TCG

vRP-TCG is an extension to add a trading card system to vRP.

## Items

Two parametric items are added:
* `tcgcard|idname[|s]`: id name is the card identifier, s is an optional argument for the shiny version
* `tcgbooster|rank|ncards`: rank is the rank of the booster (0-4), ncards is the number of cards in this booster

A nice way to use those items is to add 5 different boosters (one for each rank) of 5 cards to a TCG market.
Of course, high ranked boosters should be far more expansive than the low ranked ones.

## Cards repository

Cards are defined in repositories, which are direct access http directories with a special structure inside.
It is recommended to create your own http repositories and copy cards in them to prevents cards from disappearing if a repository creator lose his hosting solution.

* `cards.txt`: contains the list of cards in the repository (each line is a card idname), only cards referenced in this file will be availables in boosters
* `cards/<idname>*.json`: each JSON file define a card (see the format below)
* `images/cards/*.jpg,gif,png...`: contains card pictures

Card JSON structure:

```js
{
  "name": "Name of the card",
  "picture": "<path relative to images/cards/>",
  "quote": "Description of the card.",
  "rank": 0, //0-4 (common white, uncommon blue, rare yellow, very rare pink, legendary green), it also defines the rarity
  "attack": 5, //optional
  "defense": 5 //optional
}
```

For now, the TCG is not playable, so cards aren't really items or characters. By convention, characters should have attack and defense fields and items should not.

## Credits

* sword icon: https://www.flaticon.com/free-icon/sword_65741#term=sword&page=1&position=27
* shield icon: https://www.flaticon.com/free-icon/security-badge_63307#term=shield&page=1&position=19
