(deftemplate pose
 (slot x (type FLOAT))
 (slot y (type FLOAT))
 (slot pitch (type FLOAT))
 (slot order (type INTEGER))
)

(deffunction NormalizeAngle (?angle)
 (bind ?angle (mod ?angle (* 2 (pi))))
 (if (> ?angle (pi)) then
     (return (- ?angle (* 2 (pi)))))
 (if (< ?angle (- 0 (pi))) then
      (return (+ ?angle (* 2 (pi)))))
 (return ?angle)
)

(defrule generate-targets
" Creates the Target facts "
 (not(pose))
=>
 (assert (pose (x 1.0) (y 1.0) (order 1)))
 (assert (pose (x 1.0) (y 9.0) (order 2)))
 (assert (pose (x 9.0) (y 9.0) (order 3)))
 (assert (pose (x 9.0) (y 1.0) (order 4)))
 (printout yellow "Targets Generated" crlf)
)

(defrule ros-sub-init
" Subscribes and Publishes to the right topics "
 (not (ros-msgs-subscription (topic "turtle1/pose")))
 (not (execution-finalize))
=>
 (ros-msgs-create-subscription "/turtle1/pose" "turtlesim/msg/Pose")
 (printout info "Listening to /turtle1/pose" crlf)
)

(defrule ros-pub-init
" Subscribes and Publishes to the right topics "
 (not (ros-msgs-publisher (topic "turtle1/cmd_vel")))
 (not (execution-finalize))
=>
 (ros-msgs-create-publisher "/turtle1/cmd_vel" "geometry_msgs/msg/Twist")
 (printout info "Listening to /turtle1/cmd_vel" crlf)
)

(defrule ros-msgs-receive
" React to incoming messages and moves further if goal is reached"
 (ros-msgs-subscription (topic ?sub))
 ?msg-f <- (ros-msgs-message (topic ?sub) (msg-ptr ?inc-msg))
 ?pos-f <- (pose (order ?order) (x ?tx) (y ?ty))
 (not (pose (order ?order2&:(< ?order2 ?order))))
=>
 (bind ?x (ros-msgs-get-field ?inc-msg "x"))
 (bind ?y (ros-msgs-get-field ?inc-msg "y"))
 (bind ?pitch (ros-msgs-get-field ?inc-msg "theta"))
 (bind ?dx (- ?tx ?x))
 (bind ?dy (- ?ty ?y))
 (bind ?tpitch (NormalizeAngle (atan2 ?dy ?dx)))
 (bind ?dpitch (NormalizeAngle (- ?tpitch ?pitch)))
 (bind ?vel (min 1.2 (sqrt (+ (** ?dx 2) (** ?dy 2)))))
 ; (printout blue "Turtle rot " ?dpitch " tpitch " ?tpitch " pitch " ?pitch crlf)
 ; (printout red "fact" ?tx " target y" ?ty " order " ?order   crlf)
 ; (printout blue "delta " ?dx " y " ?dy crlf)
 (bind ?cmd (ros-msgs-create-message "geometry_msgs/msg/Twist"))
 (bind ?lin (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
 (bind ?ang (ros-msgs-create-message "geometry_msgs/msg/Vector3"))
 (ros-msgs-set-field ?lin "x" ?vel)
 (ros-msgs-set-field ?ang "z" ?dpitch)
 (ros-msgs-set-field ?cmd "linear" ?lin)
 (ros-msgs-set-field ?cmd "angular" ?ang)
 (ros-msgs-publish ?cmd "/turtle1/cmd_vel")
 (ros-msgs-destroy-message ?inc-msg)
 (if (< ?vel 0.1)
    then
    (retract ?pos-f)
 )
 (retract ?msg-f)
)
