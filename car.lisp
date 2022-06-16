--
-- car.lsp
--
-- Driving game demo for the lisp interpreter
-- Author: Ziga Lenarcic
-- 2021 AD
--

(load "glfw.lisp")
(load "opengl.lisp")

(set w 50.0)
(set h 100.0)

(set time (get-time))
(set input-accelerator 0.0)
(set input-steering 0.0)
(set steering-input n)
(set steering-time 0.0)
(set car-x 0.0)
(set car-y 0.0)
(set car-v 0.0)
(set car-rpm 700.0)
(set car-vx 0.0)
(set car-vy 0.0)
(set car-angle (/ pi 2))
(set wheel-angle 0.0)
(set camera 0)

(set lane-width 200)
(set road-x 0.0)
(set road-y 0.0)
(set road-angle (* 0.5 pi))
(set road n)
(set list-a n)
(set list-b n)
(set list-c n)

(loop (i 0) (< i 10) (+ i 1)
      (set len (* 2000.0 (+ 1.0 (abs (random-gauss)))))
      (set off (* 0.0015 (- (random) 0.5)))
      (print "Segment: len " len " off " off "\n")

      (set list-min-x 100000000000.0)
      (set list-max-x -100000000000.0)
      (set list-min-y 100000000000.0)
      (set list-max-y -100000000000.0)

      (set step 15.0)

      (loop (a 0.0) (< a len) (+ a step)

            (set road-angle (+ road-angle (* step off)))

            (set road-x (+ road-x (* (cos road-angle) step)))
            (set road-y (+ road-y (* (sin road-angle) step)))

            (set x1 (+ road-x (* -1.0 (sin road-angle) lane-width)))
            (set y1 (+ road-y (* (cos road-angle) lane-width)))

            (set x2 (- road-x (* -1.0 (sin road-angle) lane-width)))
            (set y2 (- road-y (* (cos road-angle) lane-width)))

            (set list-a (add-to-list (list x1 y1) list-a))
            (set list-b (add-to-list (list x2 y2) list-b))
            (set list-c (add-to-list (list road-x road-y) list-c))
            )

      (set road (add-to-list (list list-a list-b list-c) road))
      (set list-a (list (list x1 y1)))
      (set list-b (list (list x2 y2)))
      (set list-c (list (list road-x road-y)))

      --(set road-angle (+ road-angle direction))
      )

(print "Road " road "\n")

(glfwInit)
(glfwSwapInterval 1)

(set window-width 640)
(set window-height 480)
(set should-quit n)

(set window (glfwCreateWindow window-width window-height "Car\0" 0 0))

(glfwMakeContextCurrent window)

(function set-viewport (window width height)
          (set window-width width)
          (set window-height height)
          (glViewport 0 0 window-width window-height)
          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          (glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0))

(set-viewport window window-width window-height)

(function key-pressed (window key scancode action mods)
          (if (and (= key GLFW_KEY_C) (= action GLFW_PRESS))
            (set camera (if (= camera 1) 0 1)))
          (if (and (= key GLFW_KEY_ESCAPE) (= action GLFW_PRESS))
            (set should-quit 1))
          )

(define-c-callback key-callback (symbol-function 'key-pressed))
(glfwSetKeyCallback window (ccallback key-callback))

(define-c-callback resize-callback (symbol-function 'set-viewport))
(glfwSetFramebufferSizeCallback window (ccallback resize-callback))

(function draw-rectangle (x-center y-center w h)
          (glBegin GL_LINE_LOOP)
          (glVertex3d (+ 0.0 x-center (* -0.5 w)) (+ 0.0 y-center (* -0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* 0.5 w)) (+ 0.0 y-center (* -0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* 0.5 w)) (+ 0.0 y-center (* 0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* -0.5 w)) (+ 0.0 y-center (* 0.5 h)) 0.0)
          (glEnd))

(function process-input (time-delta)
          (if (= (glfwGetKey window GLFW_KEY_UP) GLFW_PRESS)
            (set input-accelerator 1.0)
            (if (= (glfwGetKey window GLFW_KEY_DOWN) GLFW_PRESS)
              (set input-accelerator -1.0)
              (set input-accelerator 0.0)))

          (if steering-input (set steering-time (+ steering-time time-delta)))
          (set steering-amount (* 0.4 (+ 3.0 steering-time) time-delta))

          (if (= (glfwGetKey window GLFW_KEY_LEFT) GLFW_PRESS)
            (do 
              (if (not steering-input) (set steering-input 1))
              (if (> input-steering 0.0)
                (set input-steering (- input-steering (* 2.5 steering-amount)))
                (set input-steering (- input-steering steering-amount))

                   ))

            (if (= (glfwGetKey window GLFW_KEY_RIGHT) GLFW_PRESS)
              (do
                (if (not steering-input) (set steering-input 1))
              (if (< input-steering 0.0)
                (set input-steering (+ input-steering (* 2.5 steering-amount)))
                (set input-steering (+ input-steering steering-amount)))
              )
              (do
                (set steering-input n)
                (set steering-time 0.0)
                (set input-steering (- input-steering (* time-delta 2.7 input-steering))))
              ))

          (if (< input-steering -1.0)
            (set input-steering -1.0)
            (if (> input-steering 1.0)
              (set input-steering 1.0)))

          (set wheel-angle (* 25.0 input-steering))
          )

(function time-step (time-delta)

          (set car-angle (+ car-angle (* 0.005 car-v time-delta -1.0 input-steering)))

          (if (< input-accelerator 0)
            (do (set car-v (+ car-v (* time-delta (* input-accelerator 3000.0))))
              (if (< car-v 0) (set car-v 0)))
            (set car-v (+ car-v (* time-delta (* input-accelerator 1000.0)))))

          (set car-v (- car-v (* car-v 0.002) (* car-v car-v 0.00001)))

          (set car-vx (* car-v (cos car-angle)))
          (set car-vy (* car-v (sin car-angle)))

          (set car-x (+ car-x (* time-delta car-vx)))
          (set car-y (+ car-y (* time-delta car-vy)))
          )


(function draw-instrument (radius min max value)
          (glBegin GL_LINE_STRIP)
          (loop (angle 140.0) (<= angle 400.0) (+ angle 5.0)
                (glVertex3d (* radius (cos (* pi (/ angle 180.0)))) (* radius (sin (* pi (/ angle 180.0)))) 0.0))
          (glEnd)

          (set angle (+ 140.0 (* 360.0 (/ (- value min) (- max min)))))
          (glColor3d 1.0 0.0 0.0)
          (glBegin GL_LINE_STRIP)
          (glVertex3d (* 0.9 radius (cos (* pi (/ angle 180.0)))) (* 0.9 radius (sin (* pi (/ angle 180.0)))) 0.0)
          (glVertex3d (* 0.0 (cos (* pi (/ angle 180.0)))) (* 0.0 (sin (* pi (/ angle 180.0)))) 0.0)
          (glEnd))

(function render ()
          (glClear GL_COLOR_BUFFER_BIT)

          (glMatrixMode GL_MODELVIEW)
          (glLoadIdentity)

          (glPushMatrix)

          (glTranslated (* 0.5 window-width) (* 0.5 window-height) 0.0)
          (glScaled 1.0 -1.0 1.0)

          (set scale 0.3)
          (glScaled scale scale scale)

          (if (= camera 1)
            (glRotated 90.0  0.0 0.0 1.0))
          (glPushMatrix)
          (if (= camera 1)
            (glRotated (* -180.0 (/ car-angle pi))  0.0 0.0 1.0))

          (glTranslated (- car-x) (- car-y) 0.0)

          -- draw road
          (loop (seg road) seg (rest seg)
                (glColor3d 1.0 1.0 1.0)
                (glBegin GL_LINE_STRIP)
                (loop (p (first (first seg))) p (rest p)
                      (glVertex3d (first (first p)) (second (first p)) 0.0)
                      )
                (glEnd)
                (glBegin GL_LINE_STRIP)
                (loop (p (second (first seg))) p (rest p)
                      (glVertex3d (first (first p)) (second (first p)) 0.0)
                      )
                (glEnd)

                (set c 0)
                (glColor3d 1.0 1.0 0.0)
                (glBegin GL_LINE_STRIP)
                (loop (p (third (first seg))) p (rest p)
                      (set c (+ c 1))
                      (if (> c 15)
                        (glColor3d 0.0 0.0 0.0))
                      (if (> c 30)
                        (do (glColor3d 1.0 1.0 0.0)
                          (set c 0)))
                      (glVertex3d (first (first p)) (second (first p)) 0.0)
                      )
                (glEnd)

                )

          (glPopMatrix)

          -- draw car
          --(glTranslated car-x car-y 0.0)
          (if (= camera 0)
            (glRotated (* 180.0 (/ car-angle pi))  0.0 0.0 1.0))
          (glColor3d 1.0 1.0 1.0)
          (glBegin GL_LINE_LOOP)
          (glVertex3d h w 0.0)
          (glVertex3d (- h) w 0.0)
          (glVertex3d (- h) (- w) 0.0)
          (glVertex3d h (- w) 0.0)
          (glEnd)

          (draw-rectangle (* -0.60 h) (* 0.8 w) 50.0 24.0)
          (draw-rectangle (* -0.60 h) (* -0.8 w) 50.0 24.0)

          (glPushMatrix)
          (glTranslated (* 0.60 h) (* 0.8 w) 0.0)
          (glRotated (* -1.0 wheel-angle) 0.0 0.0 1.0)
          (draw-rectangle 0.0 0.0 50.0 24.0)
          (glPopMatrix)
          
          (glPushMatrix)
          (glTranslated (* 0.60 h) (* -0.8 w) 0.0)
          (glRotated (* -1.0 wheel-angle) 0.0 0.0 1.0)
          (draw-rectangle 0.0 0.0 50.0 24.0)
          (glPopMatrix)

          (glPopMatrix)

          -- draw controls
          (glColor3d 0.0 0.0 1.0)
          (draw-rectangle (+ (* 0.5 window-width) (* input-steering 0.5 window-width)) 30.0 20.0 20.0)

          (glColor3d 1.0 1.0 0.5)
          (draw-rectangle 30.0 (- (* 0.5 window-height) (* input-accelerator 0.5 window-height)) 20.0 20.0)

          (glColor3d 1.0 0.3 0.0)
          (glPushMatrix)
          (glTranslated (+ (* 0.5 window-width) -60.0) (- window-height 50.0) 0)
          --(draw-rectangle 0.0 0.0 50.0 50.0)
          --(draw-instrument 50.0 0.0 1000.0 car-v)
          (glPopMatrix)

          (glColor3d 1.0 0.3 0.0)
          (glPushMatrix)
          (glTranslated (+ (* 0.5 window-width) 60.0) (- window-height 50.0) 0)
          --(draw-instrument 50.0 0.0 7000.0 car-rpm)
          (glPopMatrix)


          )

(function game-loop ()
          (set new-time (get-time))
          (set time-delta (- new-time time))
          (process-input time-delta)
          (time-step time-delta)
          (render)

          (set time new-time)

          (glfwSwapBuffers window)
          (glfwPollEvents)
          (process-lisp))

(while (and (= (glfwWindowShouldClose window) 0) (= should-quit n))
       (game-loop))

(glfwDestroyWindow window)
(glfwTerminate)
(quit 0)
