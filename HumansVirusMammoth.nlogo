;; combination of the mammoths extinction model and the virus spread model to see which effect a human virus has on the extinction of the mammoths
;; to run this model the "Americas.png" file from the netLogo Sample models (\app\models\Sample Models) is required.

  mammoths-killed-by-humans         ; counter to keep track of the number of mammoths killed by humans
  mammoths-killed-by-climate-change ; counter to keep track of the number of mammoths killed by climate change
  humans-killed-by-disease
  humans-killed-by-mammoths
  %sick
  %immune
]

breed [ mammoths mammoth ]
breed [ humans human ]


humans-own [ settled?
  sick-time    ; humans are sick for a set number of days
 remaining-immunity
 ]
turtles-own [ age immune? sick? ]

to setup
  clear-all
  ask patches [ set pcolor blue - 0.25 - random-float 0.25 ]
  import-pcolors "Americas.png"
  ask patches with [ not shade-of? blue pcolor ] [
    ; if you're not part of the ocean, you are part of the continent
    set pcolor green
  ]

  set-default-shape mammoths "mammoth"
  create-mammoths number-of-mammoths [
    set size 2
    set color brown
    set immune? true
    set sick? false
    set age random (30 * 12)  ; average mammoth age is 15
    move-to one-of patches with [ pcolor = green ]
  ]

  set-default-shape humans "person"
  create-humans number-of-humans [
    set size 2
    set color yellow
    move-to one-of patches with [ pcolor = green and pxcor <= 10 ]
    set heading -5 + random 10 ; generally head east
    set settled? false
    set age random (50 * 12) ; average human age is 25
    set sick-time 0
    set immune? false
    set sick? false
    ]
ask n-of infections-start humans [get-sick]
  set mammoths-killed-by-climate-change 0
  set mammoths-killed-by-humans 0
  set humans-killed-by-disease 0
  set humans-killed-by-mammoths 0
  reset-ticks
end


to go

  ask patches with [ pcolor = green ] [
    ; at each step, patches have a small chance
    ; to become inhospitable for mammoths
    if random-float 100 < climate-change-decay-chance [
      set pcolor green + 3
    ]
  ]

  ; mammoths move and reproduce
  ask mammoths [
    move mammoth-speed
    ; mammoths reproduce after age 3
    reproduce (3 * 12) mammoth-birth-rate
  ]
  ; humans decide whether to move or settle where
  ; they are, and then they hunt and reproduce
  ask humans [
    let mammoths-nearby mammoths in-radius 5
    ; humans have a chance of settling proportional to the
    ; number of mammoths in their immediate vicinity
    if not settled? and random 100 < count mammoths-nearby [
      set settled? true
    ]
    if not settled? [
      if any? mammoths-nearby [
        face min-one-of mammoths-nearby [ distance myself ]
      ]
      move human-speed
    ]
    if any? mammoths-here [
      let r random 100
      if r < 3  [
        set humans-killed-by-mammoths humans-killed-by-mammoths + 1
        die ] ; mammoths have a 3% chance of killing the human
      if r < 3 + odds-of-killing [
        ask one-of mammoths-here [ die ] ; successfully hunt a mammoth!
        set mammoths-killed-by-humans mammoths-killed-by-humans + 1
      ]
    ]
    reproduce (12 * 12) human-birth-rate ; humans reproduce after age 12
    if sick? [set sick-time sick-time + 1 ]
    if sick? [infect]
    if sick? [sick-die]
    if immune? [set remaining-immunity remaining-immunity - 1 ]
 ]
  die-naturally ; mammoths and humans die if they're old or crowded
  update-global-variables
  ask turtles [ set age age + 1 ]
  mutate
  tick
end

to move [ dist ] ; human or mammoth procedure
  right random 30
  left random 30
  ; avoid moving into the ocean or outside the world by turning
  ; left (-10) or right (10) until the patch ahead is not an ocean patch
  let turn one-of [ -10 10 ]
  while [ not land-ahead dist ] [
    set heading heading + turn
  ]
  forward dist
end

to get-sick
  set sick? true
  set sick-time 0
  end

to get-healthy
  set sick? false
  set sick-time 0
  set remaining-immunity immunity-duration
  set immune? true
end

to mutate
  if ticks mod mutation-freq = 0 [
    ask n-of new-sick humans [get-sick]
  ]
end

to sick-die ;; human procedure
  if sick-time < duration [ if random 100 < chance-to-die + ( age / 4 )
    [ set humans-killed-by-disease humans-killed-by-disease + 1
    die ] ]
end

;;to recover-or-die ;; turtle procedure
;;  ifelse sick-time < duration [ if random 100 < chance-recover - age / 2
;;  [ set humans-killed-by-disease humans-killed-by-disease + 1
;;    die ] ]
;;  [ get-healthy ]
;; end

to infect
  ask other turtles-here in-radius 20 with [ not sick? and not immune?]
  [ if random 100 <= infectiousness
      [ get-sick ] ]
end


to-report land-ahead [ dist ]
  let target patch-ahead dist
  report target != nobody and shade-of? green [ pcolor ] of target
end

to reproduce [ min-age birth-rate ]
  if age >= min-age and random 100 < birth-rate [
    hatch 1 [
      set age 0
      if breed = humans [
        set settled? false
        set immune? false ]
    ]
  ]
end

to die-naturally
  ask humans [
    ; humans have a 5% chance of dying if they're over 50
    if age > 50 * 12 and random-float 100 < 5 [ die ]
    ; they also get another 5% chance of dying if their density is too high
    if density > 0.75 and random-float 100 < 5 [ die ]
    ; in addition, all humans have a 0.33% chance of dying.
    if random-float 100 < 0.33 [ die ]
  ]

  ask mammoths [
    ; mammoths have a 5% chance of dying if they're over 30
    if age > 30 * 12 and random-float 100 < 5 [ die ]
    ; they also get another 5% chance of dying if their density is too high
    if density > 0.50 and random-float 100 < 5 [ die ]
    ; if they are on a patch affected by climate change, they get a 5% chance of dying
    if [ pcolor ] of patch-here = green + 3 and random-float 100 < 5 [
      set mammoths-killed-by-climate-change mammoths-killed-by-climate-change + 1
      die
    ]
    ; finally, all mammoths have a 0.33% chance of dying.
    if random-float 100 < 0.33 [ die ]
  ]
end



to-report density ; turtle reporter
  let nearby-turtles (turtle-set turtles-on neighbors turtles-here)
  report (count nearby-turtles with [ breed = [ breed ] of myself ]) / 9
end

to update-global-variables
  if count turtles > 0
    [ set %sick (count humans with [ sick? ] / count humans) * 100
      set %immune (count humans with [ immune? ] / count humans) * 100 ]
end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
