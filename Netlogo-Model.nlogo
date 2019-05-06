globals [
  municipality-list
  housetype-list
  company-locations
  years
  months
  total-population
  total-capacity
  list-production
  production-equation
  national-recycling-percentage
  profit
  target-not-met
  times-pay-fine
  extra-waste
  total-delivered
  final-recycled-percentage
  total-recycled-plastic
]

breed [municipalities municipality]
breed [households household]
breed [companies company]

turtles-own [
  balance
  budget
  budget-left
  investment-incentivizing
  investment-knowledge
  type-household
  municipality-name
  my-municipality
  single
  couple
  family
  retired
  surface
  number-households
  central-points
  central
  handed-in
  seperation-percentage
  price
  capacity
  technology
  remaining-capacity
  fine
  knowledge
  month-delivered
  requested-waste
  my-company
  recycled-plastic
  ticks-since-here
  waiting
  earnings
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; SETUP PROCEDURES ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-globals
  setup-municipalities
  setup-households
  setup-companies
  reset-ticks
end

to setup-globals
  set national-recycling-percentage 12.5
  set profit 788
  set production-equation (40 - 0.04 * 1 - exp(-0.01 * 1) * sin (0.3 * 1))
  set municipality-list (list ["Amsterdam" red 15 225274 100765 92250 44039 165 462328] ["Rotterdam" green 10 130326 75790 77290 36374 206 319780]
                              ["The Hague" blue 5 104962 58028 67887 26313 83 257190] ["Delft" orange 0 27597 12083 10622 6893 23 57195]
                              ["Emmen" pink -5 12939 13880 14550 6915 337 48284] ["De Marne" grey -10 1285 1352 1273 748 167 4658]
                              ["Blaricum" yellow -15 1043 1279 1366 837 11 4525])
  set housetype-list (list ["Single" -12 "house" ] ["Couple" -8 "house bungalow"]
                           ["Family" -4 "house two story"] ["Retired" -0 "house efficiency" ] )
  set total-population item 8 item 0  municipality-list + item 8 item 1 municipality-list + item 8 item 2 municipality-list
                     + item 8 item 2 municipality-list + item 8 item 3 municipality-list + item 8 item 4 municipality-list
                     + item 8 item 5 municipality-list  + item 8 item 6 municipality-list
  set months 1
end

to setup-municipalities
  create-municipalities 7
  ask municipalities [
    set shape "house colonial"
    set size 3
    set color item 1 item 0 municipality-list
    set municipality-name item 0 item 0 municipality-list
    set ycor item 2 item 0 municipality-list
    set xcor -14.5
    set single item 3 item 0 municipality-list
    set couple item 4 item 0 municipality-list
    set family item 5 item 0 municipality-list
    set retired item 6 item 0 municipality-list
    set surface item 7 item 0 municipality-list
    set number-households item 8 item 0 municipality-list
    set knowledge (random (10) + initial-percentage-knowledge) / 100
    set central-points surface / cp-ratio
    if number-households / central-points >= 1500 [set central 1]
    if central = 1
      [set handed-in (40 + initial-percentage-incentivizing) / 100]
      if central = 0
      [set handed-in (60 + initial-percentage-incentivizing) / 100]
    set municipality-list but-first municipality-list]
end

to setup-households
  ask municipalities [
    hatch-households 1
    [set shape item 2 item 0 housetype-list
     set xcor item 1 item 0 housetype-list
     set type-household item 0 item 0 housetype-list
      set my-municipality myself]
    hatch-households 1
    [set shape item 2 item 1 housetype-list
     set xcor item 1 item 1 housetype-list
     set type-household item 0 item 1 housetype-list
      set my-municipality myself]
    hatch-households 1
    [set shape item 2 item 2 housetype-list
     set xcor item 1 item 2 housetype-list
     set type-household item 0 item 2 housetype-list
      set my-municipality myself]
    hatch-households 1
    [set shape item 2 item 3 housetype-list
     set xcor item 1 item 3 housetype-list
      set type-household item 0 item 3 housetype-list
  set my-municipality myself]]
  ask households [set size 2]
end

to setup-companies
  set company-locations 15
  create-companies 10
  ask companies [
    set shape "garbage can"
    set size 2.2
    set xcor 15
    set color white
    set ycor company-locations
    set company-locations company-locations - 3.2
    setup-technology]
end

to setup-technology
  set total-capacity sum [number-households] of municipalities * 0.068 * mean [handed-in] of municipalities * 4 * (40 - 0.04 - exp(-0.01) * sin (0.3))
      set technology random 3 + 1 ; 1 = low, 2 = medium, 3 = high
  ifelse technology = 1 [set seperation-percentage (random 10 + 65) / 100 ; Technology 1 is the worse technology, with the lowest recycle percentage and capacity
      set capacity 0.1 * total-capacity
      set price (random 30 + 70) / 100 ]
  [ifelse technology = 2 [set seperation-percentage (random 10 + 75) / 100 ; Technology 2 is a medium technology, with a medium recycle percentage and capacity
      set capacity 0.25 * total-capacity
      set price (random 30 + 70) / 100]
     [set seperation-percentage (random 10 + 85) / 100  ; Technology 3 is the best technology, with the highest recyle percentage and capacity
      set capacity 0.5 * total-capacity
      set price (random 30 + 70) / 100]]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; MAIN PROCEDURE ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  handle-waste
  monthly-procedures
  yearly-procedures
  set-hierarchy
  ask companies [check-technology]
  ask municipalities [show-name]
  ask households [show-size]
  stop-running
tick
end

;; VISUALISATION ;;

to show-name
  ifelse show-municipality-name?
    [set label municipality-name ]
    [set label ""]
end

to show-size
  ifelse show-amount-households?
    [ask households with [shape = "house"] [
      set label Single]] [set label ""]
  ifelse show-amount-households? [
    ask households with [shape = "house bungalow"] [
      set label Couple]] [set label ""]
  ifelse show-amount-households? [
    ask households with [shape = "house two story"] [
      set label Family]] [set label ""]
  ifelse show-amount-households? [
    ask households with [shape = "house efficiency"] [
      set label Retired]] [set label ""]
end

;; WEEKLY ;;

to handle-waste
  ifelse ticks > 0 and remainder ticks 4 = 0 [produce collect]
  [produce]
end

to produce
  ask municipalities [if ticks > 0 [set month-delivered month-delivered +
  (single * 0.75 * 0.068 * handed-in * production-equation) +
  (couple * 1.25 * 0.068 * handed-in * production-equation) +
  (family * 1.5 * 0.068 * handed-in * production-equation) +
  (retired * 0.5 * 0.068 * handed-in * production-equation)]]
end

;; MONTHLY ;;

to monthly-procedures
if ticks > 0 and remainder ticks 4 = 0 [
    set months months + 1
    ask municipalities [
      set knowledge knowledge + (investment-knowledge / (3 * 13)) ; adding the amount of knowledge that is gained in *budet-municipality* (knowledge is calculated for three years, so it has to be divided by 3 * 13 to calculate knowledge increase per month)
      set handed-in handed-in + (investment-incentivizing / (3 * 13))] ; adding the amount of importance that is gained in *budet-municipality* (incentivizing is calculated for three years, so it has to be divided by 3 * 13 to calculate the importance increase per month)
    set production-equation (40 - 0.04 * months - exp(-0.01 * months) * sin (0.3 * months))]
end

to collect
  let que []
  set que sort-on [number-households] municipalities
  foreach que [ordered-municipalities -> ask ordered-municipalities [
   set total-delivered total-delivered + month-delivered ; the total-delivered and month-delivered is about the handed-in plastic stream
   set balance month-delivered - requested-waste
   ifelse balance >= 0 [ask my-company [set recycled-plastic [requested-waste] of myself * [knowledge] of myself * seperation-percentage]
                                        set total-recycled-plastic total-recycled-plastic + recycled-plastic
                                        set extra-waste extra-waste + balance]
                       [ask my-company [set recycled-plastic [month-delivered] of myself * [knowledge] of myself * seperation-percentage
                                        set total-recycled-plastic total-recycled-plastic + recycled-plastic]]
   ifelse balance < 0  [ask my-company [set earnings earnings + (fine * abs(balance) + recycled-plastic * profit)] set times-pay-fine times-pay-fine + 1]
                       [ask my-company [set earnings earnings + recycled-plastic * profit]]
   if handed-in * knowledge * [seperation-percentage] of my-company < (national-recycling-percentage / 100) [set target-not-met target-not-met + 1]
   set final-recycled-percentage total-recycled-plastic / total-delivered * 100
   set month-delivered 0]]
end

;; YEARLY ;;

to yearly-procedures
  if ticks > 0 and remainder ticks 52  = 0 [
    set years years + 1
    set national-recycling-percentage national-recycling-percentage + 0.25]
end

;; THREE YEARLY ;;

to set-hierarchy
  if ticks = 0 or remainder ticks (52 * contract-length) = 0 [
    ask municipalities [set requested-waste number-households * 0.068 * handed-in * 4 * (40 - 0.04 * months - exp(-0.01 * months) * sin (0.3 * months))]
    ask companies [set remaining-capacity capacity]
    clear-links
    ask municipalities [set my-company nobody]
    set list-production sort-on [requested-waste] municipalities
    set list-production reverse list-production
    foreach list-production [ranked-municipality ->
    ask ranked-municipality [choose-contract]]]
end

to choose-contract
  let my-list []
  let candidate1 companies with [remaining-capacity >= [requested-waste] of myself and seperation-percentage * [knowledge] of myself * [handed-in] of myself >= ((national-recycling-percentage / 100) - 0.5)]
  let candidate2 companies with [remaining-capacity >= [requested-waste] of myself]
  ifelse any? candidate1 [
  set my-list sort-on [technology] candidate1
    ask candidate1 [
      set fine [requested-waste] of myself * profit * price]
     ifelse length my-list > 1 [
     ifelse [fine] of item 0 my-list <= [fine] of item 1 my-list [
      set my-company item 0 my-list
      create-link-to my-company]
    [set my-company item 1 my-list
      create-link-to my-company]]
    [set my-company item 0 my-list
      create-link-to my-company]
    ask my-company [set remaining-capacity remaining-capacity - [requested-waste] of myself]]
     [ifelse any? candidate2
     [set my-list sort-on [technology] candidate2
    ask candidate2 [set fine [requested-waste] of myself * profit * price]
     ifelse length my-list > 1 [
     ifelse [fine] of item 0 my-list <= [fine] of item 1 my-list [
      set my-company item 0 my-list
      create-link-to my-company]
    [set my-company item 1 my-list
      create-link-to my-company]]
    [set my-company item 0 my-list
      create-link-to my-company]
      ask my-company [set remaining-capacity remaining-capacity - [requested-waste] of myself]]
    [set my-list sort-on [remaining-capacity] companies
      set my-company item 0 my-list
      create-link-to my-company
      set requested-waste requested-waste - remaining-capacity
      ask my-company [set remaining-capacity remaining-capacity - [requested-waste] of myself]
      if requested-waste > 0 [choose-contract]]]
  budget-municipality
end

to budget-municipality
  set budget 10 + extra-budget
  set budget budget - [technology] of my-company
  if central = 0
    [set budget budget - 4]
  if central = 1
    [set budget budget - 2]
  set budget-left budget
  ifelse knowledge < 1 and handed-in < 1 [
    set investment-knowledge (budget-left / 100) / 2
    set investment-incentivizing budget-left / 100 / 2]
  [ifelse knowledge < 1 [set investment-knowledge (budget-left / 100)]
    [if handed-in < 1 [ set investment-incentivizing (budget-left / 100)]]]
end

;; NOT TIME SPECIFIC ;;

to check-technology
  if ability-to-invest = true [
  ifelse waiting = true [wait-a-year]
  [if years > 4 and technology < 3 and earnings > 0 and earnings >= 0.4 * mean [earnings] of companies [wait-a-year set waiting true]]]
end

to wait-a-year
  ifelse ticks - ticks-since-here > 52 and ticks-since-here != 0
  [set ticks-since-here 0
    ifelse earnings >= 0.6 * mean [earnings] of companies and technology <= 2 [large-investment-tech] [small-investment-tech]]
  [if ticks-since-here = 0 [set ticks-since-here ticks]]
end

to small-investment-tech
  set waiting false
  set technology technology + 0.5
  set seperation-percentage seperation-percentage + (random 6 + 5 ) / 100 ; between 5 and 10 percent
  if competition = true [set price price + random 5 + 1] ; between 1 and 5 percent
  set earnings earnings * (5 / 6)
end

to large-investment-tech
  set waiting false
  set technology technology + 1
  set seperation-percentage seperation-percentage + (random 6 + 5 ) / 100
  set capacity capacity + (random 3 + 1 ) * (1 / 3) * mean [month-delivered] of municipalities ; increases 1/3, 2/3 or 1 times the average of the month production of municipalities
  if competition = true [set price price + random 6 + 5] ; between the 5 and 10 percent
  set earnings earnings * (4 / 5)
end

;;;;;;;;;;;;;;;;;;;;;;
;;; STOP CONDITION ;;;
;;;;;;;;;;;;;;;;;;;;;;

to stop-running ; The model has to run for 20 years, so from the beginning of 2018 until the end of 2038.
  if 2018 + years = 2038 [
    user-message "20 years have past!"
    stop]
end
@#$#@#$#@
GRAPHICS-WINDOW
264
11
769
517
-1
-1
15.061
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
7
60
70
93
go
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

BUTTON
7
95
70
128
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

MONITOR
86
10
143
55
Year
2018 + years
17
1
11

MONITOR
147
10
255
55
Recycling target %
national-recycling-percentage
17
1
11

SWITCH
8
357
201
390
show-municipality-name?
show-municipality-name?
0
1
-1000

BUTTON
7
20
82
53
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
8
398
211
431
show-amount-households?
show-amount-households?
0
1
-1000

PLOT
1380
170
1596
322
Mean Remaining Capacity (tons)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [remaining-capacity] of companies"

PLOT
1147
16
1377
169
Production-equation (tons)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot production-equation"

MONITOR
1062
115
1145
160
NIL
target-not-met
17
1
11

PLOT
773
172
967
322
Sum Technology Levels
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [technology] of companies"

PLOT
772
326
1312
515
Total Plastic Delivered and Total Recycled Plastic (tons)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total-production (handed-in)" 1.0 0 -16777216 true "" "plot total-delivered"
"Total-recycled-plastic" 1.0 0 -3508570 true "" "plot total-recycled-plastic"

PLOT
1318
325
1596
514
Education (%)
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Knowledge" 1.0 0 -955883 true "" "plot mean [knowledge] of municipalities"
"Incentivising" 1.0 0 -13345367 true "" "plot mean [handed-in] of municipalities"

PLOT
972
171
1378
322
Mean Earnings and Mean Recycled Plastic
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Earnings (euros)" 1.0 1 -2064490 true "" "plot mean [earnings] of companies"
"Recycled Plastic (tons E5)" 1.0 0 -10873583 true "" "plot mean [recycled-plastic] of companies * 100000"

PLOT
1380
17
1595
169
Sum Recycled Plastic (tons)
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [recycled-plastic] of companies"

CHOOSER
7
176
145
221
cp-ratio
cp-ratio
0.5 1 50
1

SLIDER
7
277
216
310
initial-percentage-knowledge
initial-percentage-knowledge
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
7
318
218
351
initial-percentage-incentivizing
initial-percentage-incentivizing
-20
20
0.0
1
1
NIL
HORIZONTAL

SLIDER
74
136
218
169
extra-budget
extra-budget
0
4
0.0
1
1
NIL
HORIZONTAL

SWITCH
75
61
217
94
ability-to-invest
ability-to-invest
0
1
-1000

MONITOR
977
115
1058
160
NIL
times-pay-fine
17
1
11

MONITOR
977
65
1144
110
NIL
extra-waste
17
1
11

CHOOSER
8
226
146
271
contract-length
contract-length
1 3
1

PLOT
773
19
973
169
Final Recycled (%)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"final-recycled-percentage" 1.0 0 -16777216 true "" "plot final-recycled-percentage"

MONITOR
977
17
1144
62
NIL
final-recycled-percentage
17
1
11

SWITCH
75
97
219
130
competition
competition
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

In this model, seven Dutch municipalities are modelled, together with ten recycling companies. The different households of the municipalities produce waste, of which a certain part is plastic. A certain part of the plastic is handed in by the households. Municipalities close contracts with companies to collect their plastic waste. The goal of this model is to gain insight into the current market of plastic waste management, where the main output to evaluate is in terms of % recycled plastic of the handed in plastic waste.

## HOW IT WORKS

The model code starts with a specification of all the global variables. After that three breeds, which are agents, are formed: municipalities, households and recycling companies. For the agents are ‘turtles-own’ variables specified. Then the set-up phase is coded, among other things the globals are set-up. For the agents this is done separately. Also a set-up of the technologies is done, here for example the price, recycling percentage and the capacity is specified. In the set-up a technology is assigned to a company.

In the main procedure there is a separation made in the weekly, monthly, yearly and three yearly actions. Every week, which is one tick, the households produce waste. It depends on the type of household how much is produced. Every month the hand in plastic waste is collected by the companies at the municipalities they have a contract with. There is checked if the municipalities delivered enough plastic waste, as stated in their contract. If this is not the case, a process is started that the municipality has to pay a fine for the missing tons. Furthermore, the companies process the waste and get money for the recycled plastic from the government. In the end the company adds all the earnings from the fines and the recycled plastic, so the total earnings of the companies can be calculated. Yearly the households within the municipalities learn from the incentivizing and knowledge activities (if the municipality invested in this, which will be mentioned later). Every three years, old contracts are broken and new contracts are closed. First is defined which municipality can choose a company first. This is determined by the requested amount of plastic the municipality want to have collected. Then, following the order the municipalities can form contracts, is checked which companies have the capacity to collect the requested amount of plastic by the municipality. After that is checked if the technologies of those companies can meet the target set by the government taken into account the knowledge of plastic recycling the households have for the specific municipality. The two companies that match the best will be considered by the municipality. The company (one of the two) with the lowest fine is chosen and a contract is closed. Everytime a contract is closed the company lowers its remaining capacity with the requested amount of plastic stated by the municipality. Lastly, the municipality distributes the residual budget over investments in incentivizing and knowledge. This will happen for all the municipalities sequential. There is also a procedure included that makes sure the model stops running when twenty years passed.

In addition, the model includes the option of investment in technology by the recycling companies. When the companies have built up five years of earnings, they can check if their earnings are large enough to upgrade their technology, and if the maximum technology is not yet reached. An investment can be small, which means that only the separation technology (recycle percentage) improves, or large, which means that both the separation technology improves and the capacity becomes bigger.

## HOW TO USE IT

Adjust the slider parameters (see below), or use the default settings.
Press the ‘setup’ button.
Press the ‘go’ button, the simulation will start.
Look at the monitors to see how the plastic waste collection develops over the years.

Parameters:
Ability-to-invest; the default setting is set on ‘true’, which means that the companies have the option to invest in new technologies. It is also possible to choose to set this variable on ‘false’ and then the companies do not invest in new technologies.
CP-ratio; the default setting is set on ‘1’, which means that there is 1 central collection point per km2. If this ratio is set low the infrastructure of the municipalities is more likely to be decentral and if the ratio is set high the infrastructure of the municipalities is more likely to be central.
Contract-length; the default setting is set on ‘3’, which means that the contracts between the municipalities and the companies last for three year. The contract length can be set shorter.
Initial-percentage-knowledge; the default setting is set on ‘40’, this means that all the households start with a knowledge percentage of 40%, which means that 40% of the handed-in plastic recyclable plastic is. The initial percentage knowledge can be set higher or lower.
Initial-percentage-incentivizing; the default setting is set on ‘0’, this means that all the households start with an importance percentage of 40% for a centralized infrastructure and 60% for a decentralized structure. The initial percentage incentivizing can be set higher or lower, this means the starting percentage of handed-in plastic increases or decreases.

There are a couple of monitors to show the development of the plastic waste collection over the years. First of all, four output variables are shown as monitors. Also the current year and the national recycling target set by the government are shown in monitors. Furthermore, some different graphs are shown, like the earnings of the companies, the remaining capacity, the development of the base waste of the households, the amount of recycled plastic in total and per month, the level of the technologies and the development of education (knowledge and incentivizing).

The model stops when twenty years passed. When the year turns from 2038 into 2039 the model stops running.


## CREDITS AND REFERENCES

A.R. Boijmans - 4306422

A.R.K. Renaud - 4305132

N.M.J. Roes - 4290119
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

garbage can
false
0
Polygon -16777216 false false 60 240 66 257 90 285 134 299 164 299 209 284 234 259 240 240
Rectangle -7500403 true true 60 75 240 240
Polygon -7500403 true true 60 238 66 256 90 283 135 298 165 298 210 283 235 256 240 238
Polygon -7500403 true true 60 75 66 57 90 30 135 15 165 15 210 30 235 57 240 75
Polygon -7500403 true true 60 75 66 93 90 120 135 135 165 135 210 120 235 93 240 75
Polygon -16777216 false false 59 75 66 57 89 30 134 15 164 15 209 30 234 56 239 75 235 91 209 120 164 135 134 135 89 120 64 90
Line -16777216 false 210 120 210 285
Line -16777216 false 90 120 90 285
Line -16777216 false 125 131 125 296
Line -16777216 false 65 93 65 258
Line -16777216 false 175 131 175 296
Line -16777216 false 235 93 235 258
Polygon -16777216 false false 112 52 112 66 127 51 162 64 170 87 185 85 192 71 180 54 155 39 127 36

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1040"/>
    <metric>final-recycled-percentage</metric>
    <metric>target-not-met</metric>
    <metric>extra-waste</metric>
    <metric>times-pay-fine</metric>
    <enumeratedValueSet variable="initial-percentage-knowledge">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contract-length">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ability-to-invest">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cp-ratio">
      <value value="0.5"/>
      <value value="1"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-percentage-incentivizing">
      <value value="-20"/>
      <value value="0"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extra-budget">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
