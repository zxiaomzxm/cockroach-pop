globals
[
  cockroaches-stride ;; how much a cockroach moves in each simulation step
  cockroach-size    ;; the size of the shape for a cockroach
  trap-size      ;; the size of the shape for a trap
  poison-size    ;; the size of the shape for a poison bait
  cockroach-reproduce-age ;; age at which cockroach reproduces
  cockroaches-born ;; number of cockroaches born
  cockroaches-died ;; number of cockroaches that died
  max-cockroaches-age
  amount-of-food-cockroaches-eat
  min-reproduce-energy-cockroaches ;; how much energy, at minimum, cockroach needs to reproduce
  max-cockroaches-offspring ;; max offspring a cockroach can have

  max-object-energy ;; the maximum amount of energy a object in a patch can accumulate
  sprout-delay-time ;; number of ticks before trash starts regrowing
  trash-level ;; a measure of the amount of trash currently in the ecosystem
  trash-growth-rate ;; the amount of energy units a object gains every tick from regrowth
  ;immunity-duration ;; how many weeks immunity lasts

  cockroaches-color
  trash-color
  traps-color
  dirt-color
  poison-color
]

breed [ cockroaches cockroach ]
breed [ traps trap ]
breed [ poisons poison ]
breed [ disease-markers a-disease-marker ] ;; visual cue, red "X" that cockroach has a disease and will die
breed [ embers ember ] ;; visual cue that a trash patch is on fire

turtles-own [ energy current-age max-age female? #-offspring]

cockroaches-own
  [ sick?                ;; if true, the turtle is infectious
    remaining-immunity   ;; how many weeks of immunity the turtle has left
    sick-time
  ]

patches-own [ fertile?  object-energy countdown]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; setup procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set cockroaches-born 0
  set cockroaches-died 0

  set cockroach-size 1.2
  set trap-size 2.0
  set poison-size 2.0
  ;set immunity-duration 24 * 60
  set cockroaches-stride 0.3
  set cockroach-reproduce-age 60
  set min-reproduce-energy-cockroaches 30
  set max-cockroaches-offspring 2
  set max-cockroaches-age 1000
  set amount-of-food-cockroaches-eat 4.0
  set trash-level 0

  set sprout-delay-time 25
  set trash-growth-rate 5
  set max-object-energy 100

  set cockroaches-color (black)
  set trash-color (green)
  set traps-color (violet)
  set dirt-color (white)
  set poison-color (red)
  set-default-shape cockroaches "bug"
  set-default-shape traps "box"
  set-default-shape poisons "box"
  set-default-shape embers "x"
  reset-ticks
  add-starting-trash
  add-cockroaches
  ;add-traps
  update-display
  
  reset-ticks
end

to add-starting-trash
  let number-patches-with-trash (floor (amount-of-trash * (count patches) / 100))
  ask patches [
      set fertile? false
      set object-energy 0
    ]
  ask n-of number-patches-with-trash patches  [
      set fertile? true
      set object-energy max-object-energy / 2
    ]
  ask patches [color-trash]
end

to add-cockroaches
  create-cockroaches initial-number-cockroaches  ;; create the cockroaches, then initialize their variables
  [
    set color cockroaches-color
    set size cockroach-size
    set energy 20 + random 20 - random 20 ;; randomize starting energies
    set current-age 0  + random max-cockroaches-age     ;; start out cockroaches at different ages
    set max-age max-cockroaches-age
    set #-offspring 0
    setxy random world-width random world-height
    get-healthy
  ]
  ;ask n-of 10 cockroaches [ get-sick ]
end

to get-healthy ;; turtle procedure
  set sick? false
  set remaining-immunity 0
  set sick-time 0
end

to get-sick ;; turtle procedure
  set sick? true
  set remaining-immunity 0
end

to become-immune ;; turtle procedure
  set sick? false
  set sick-time 0
  set remaining-immunity immunity-duration
end

to add-traps
  create-traps number-traps  ;; create the traps, then initialize their variables
  [
    set color traps-color
    set size trap-size
    setxy random world-width random world-height
  ]
end

to add-poison-bait
  create-poisons 1  ;; create a poison-bait, then initialize their variables
  [
    set color poison-color
    set size poison-size
    setxy random world-width random world-height
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; runtime procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
;if ticks >= 1000 and constant-simulation-length? [stop]
  ask cockroaches [
    cockroaches-live
    if sick? [ recover-or-die ]
    ifelse sick? [ infect ] [ reproduce-cockroaches ]
    ]
  ask traps [
    trap-cockroaches
    ]
  ask poisons [
    poision-cockroaches
  ]
  ask patches [
    set countdown random sprout-delay-time
    grow-trash
    ]   ;; only the fertile patches can grow trash
  fade-embers
  age-disease-markers
  update-display
  tick
end

to kill-a-%-of-cockroaches
  ;; procedure for removing a percentage of cockroaches (when button is clicked)
  let number-cockroaches count cockroaches
  ask n-of floor (number-cockroaches * strength-of-killing / 100) cockroaches [
    hatch 1 [
     set current-age  0
     set breed disease-markers
     set size 1.5
     set shape "x"
     set color red
     ]
    set cockroaches-died (cockroaches-died + 1)
    die
  ]
end

to trap-cockroaches  ;; traps procedure
    if (any? cockroaches-here)
        [ask cockroaches-here
          [die]
         ]
end

to poision-cockroaches   ;; poison procedure
  if (any? cockroaches-here)
  [if random-float 100 < poison-infectious
    [ask cockroaches-here
    [get-sick]]
    ]
end

to dump
  let current-trash-patches patches with [fertile?]
  let current-burn-patches n-of floor ( (count current-trash-patches) * degree-of-dumping / 100) current-trash-patches
  ask current-burn-patches [
    set countdown sprout-delay-time
    set object-energy 0
    color-trash
    create-ember
    ]
end

to create-ember ;; patch procedure
  sprout 1 [
    set breed embers
    set current-age (round countdown / 4)
    set color [255 255 0 255]
    set size 1
    set color red
    ]
end

to age-disease-markers
  ask disease-markers [
      set current-age (current-age  + 1)
      set size (1.5 - (1.5 * current-age  / 20))
      if current-age  > 25  or (ticks = 999)  [die]
   ]
end

to fade-embers
  let ember-color [red]
  let transparency 0
  ask embers [
    set shape "x"
    set current-age (current-age - 1)
    set transparency round floor current-age * 255 / sprout-delay-time
   ;; show transparency
    set ember-color lput transparency [255 155 0]
  ;;  show ember-color
    if current-age <= 0 [die]
    set color ember-color
  ]
end

to cockroaches-live
    move-cockroaches
    set energy (energy - 1)  ;; cockroaches lose energy as they move
    set current-age (current-age + 1)
    if immune? [ set remaining-immunity remaining-immunity - 1 ]
    if sick? [ set sick-time sick-time + 1 ]
    cockroaches-eat-trash
    death
end

to move-cockroaches
  rt random 50 - random 50
  fd cockroaches-stride
end

;; If a cockroach is sick, it infects other cockroaches on the same patch.
;; Immune cockroaches don't get sick.
to infect ;; cockroaches procedure
  ask other cockroaches-here with [ not sick? and not immune? ]
    [ if random-float 100 < poison-infectious
      [ get-sick ] ]
end

;; Once the cockroach has been sick long enough, it
;; either recovers (and becomes immune) or it dies.
to recover-or-die ;; cockroaches procedure
  if sick-time > duration                        ;; If the cockroach has survived past the virus' duration, then
    [ ifelse random-float 100 < chance-recover   ;; either recover or die
      [ become-immune ]
      [ die ] ]
end

to-report immune?
  report remaining-immunity > 0
end

to update-display
  ask cockroaches
    [ set color ifelse-value sick? [ red ] [ ifelse-value immune? [ blue ] [ black ] ] ]
end

to cockroaches-eat-trash  ;; cockroaches procedure
  ;; if there is enough trash to eat at this patch, the cockroaches eat it
  ;; and then gain energy from it.
  if object-energy > amount-of-food-cockroaches-eat  [
    ;; objects lose ten times as much energy as the cockroaches gains (trophic level assumption)
    set object-energy (object-energy - (amount-of-food-cockroaches-eat * 10))
    set energy energy + amount-of-food-cockroaches-eat  ;; cockroaches gain energy by eating

  ]
  ;; if object-energy is negative, make it positive
  if object-energy <=  amount-of-food-cockroaches-eat  [set countdown sprout-delay-time ]
end

to reproduce-cockroaches  ;; cockroaches procedure
  let number-new-offspring (random (max-cockroaches-offspring + 1)) ;; set number of potential offpsring from 1 to (max-cockroaches-offspring)
  if (energy > ((number-new-offspring + 1) * min-reproduce-energy-cockroaches)  and current-age > cockroach-reproduce-age)
  [
      set energy (energy - (number-new-offspring  * min-reproduce-energy-cockroaches))      ;;lose energy when reproducing --- given to children
      set #-offspring #-offspring + number-new-offspring
      set cockroaches-born cockroaches-born + number-new-offspring
      ifelse sick? = true
      [hatch number-new-offspring
        [
          set size cockroach-size
          set energy min-reproduce-energy-cockroaches ;; split remaining half of energy amongst litter
          set current-age 0
          set #-offspring 0
          rt random 360 fd cockroaches-stride  ;; hatch an offspring set it heading off in a a random direction and move it forward a step
          get-sick
        ]
      ]
      [hatch number-new-offspring
        [
          set size cockroach-size
          set energy min-reproduce-energy-cockroaches ;; split remaining half of energy amongst litter
          set current-age 0
          set #-offspring 0
          rt random 360 fd cockroaches-stride  ;; hatch an offspring set it heading off in a a random direction and move it forward a step
          get-healthy
        ]
       ]
  ]
end

to death
  ;; die when energy dips below zero (starvation), or get too old
  if (current-age > max-age) or (energy < 0)
  [ set cockroaches-died (cockroaches-died + 1)
    die ]
end

to grow-trash  ;; patch procedure
  set countdown (countdown - 1)
  ;; fertile patches gain 1 energy unit per turn, up to a maximum max-object-energy threshold
  if fertile? and countdown <= 0
     [set object-energy (object-energy + trash-growth-rate)
       if object-energy > max-object-energy
       [set object-energy max-object-energy]
       ]
  if not fertile?
     [set object-energy 0]
  if object-energy < 0 [set object-energy 0 set countdown sprout-delay-time]
  color-trash
end

to color-trash
  ifelse fertile? [
    ifelse object-energy > 0
    ;; scale color of patch from whitish green for low energy (less foliage) to green - high energy (lots of foliage)
    [set pcolor (scale-color green object-energy  (max-object-energy * 2)  0)]
    [set pcolor dirt-color]
    ]
  [set pcolor dirt-color]
end
@#$#@#$#@
GRAPHICS-WINDOW
551
13
1124
607
23
23
11.98
1
10
1
1
1
0
1
1
1
-23
23
-23
23
0
0
1
ticks
30.0

BUTTON
15
21
100
58
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
113
21
210
58
go/pause
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
231
21
404
54
degree-of-dumping
degree-of-dumping
1
100
95
1
1
%
HORIZONTAL

BUTTON
410
21
536
54
dump
dump
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
410
116
538
149
kill cockroach
kill-a-%-of-cockroaches
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
230
116
405
149
strength-of-killing
strength-of-killing
1
100
99
1
1
%
HORIZONTAL

SLIDER
230
69
404
102
number-traps
number-traps
0
20
10
1
1
NIL
HORIZONTAL

BUTTON
409
69
537
102
add traps
add-traps
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
69
211
102
amount-of-trash
amount-of-trash
0
100
100
1
1
%
HORIZONTAL

SLIDER
14
116
210
149
initial-number-cockroaches
initial-number-cockroaches
0
300
30
1
1
NIL
HORIZONTAL

SLIDER
229
347
404
380
poison-infectious
poison-infectious
0
100
95
1
1
%
HORIZONTAL

BUTTON
410
347
537
425
poison bait
add-poison-bait
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
13
164
535
333
Population Size vs. Time
time
population size
0.0
1000.0
0.0
600.0
true
true
"" "set trash-level ( sum [object-energy] of patches / (max-object-energy ))"
PENS
"cockroaches" 1.0 0 -8053223 true "" "plot count cockroaches"
"trash" 1.0 0 -13840069 true "" "plot trash-level"

PLOT
13
438
534
601
Poision effect
time
Population
0.0
1000.0
0.0
600.0
true
true
"" ""
PENS
"susceptible" 1.0 0 -13840069 true "" "plot count cockroaches with [ not sick? and not immune? ]"
"infective" 1.0 0 -8053223 true "" "plot count cockroaches with [ sick? ]"
"immune" 1.0 0 -13345367 true "" "plot count cockroaches with [ immune? ]"
"total" 1.0 0 -16777216 true "" "plot count cockroaches"

SLIDER
15
347
209
380
duration
duration
1
100
100
1
1
NIL
HORIZONTAL

SLIDER
228
392
404
425
chance-recover
chance-recover
0
100
0
1
1
%
HORIZONTAL

SLIDER
15
392
210
425
immunity-duration
immunity-duration
0
200
0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
