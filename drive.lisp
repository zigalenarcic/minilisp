--
-- drive.lisp
--
-- Driving game demo for the lisp interpreter
-- Author: Ziga Lenarcic
-- 2021 AD
--

(load "sdl.lisp")
(load "opengl.lisp")
(load "glfont.lisp")

(set *window* n)
(set *context* n)
(set *should-quit* n)

(set *time* (get-time))
(set *keyboard-state* n)

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
(set car-angle (/ pi -2))
(set wheel-angle 0.0)
(set camera 0)

(set lane-width 200)
(set road-x 0.0)
(set road-y 0.0)

(set prev-road-x 0.0)
(set prev-road-y 0.0)

(set road-angle (* 0.5 pi))
(set road n)
(set list-a n)
(set list-b n)
(set list-c n)
(set list-ground n)
(set list-cliff n)
(set list-road n)
(set list-line n)

(set line-width 4.0)

(set line-length 0.0)
(set line-length-single 800.0)

(loop (i 0) (< i 10) (+ i 1)
      (set len (* 1500.0 (+ 1.0 (abs (random-gauss)))))
      (set off (* 0.0015 (- (random) 0.5)))
      (print "Segment: len " len " off " off "\n")

      (set list-min-x 100000000000.0)
      (set list-max-x -100000000000.0)
      (set list-min-y 100000000000.0)
      (set list-max-y -100000000000.0)

      (set step 15.0)
      --(set step 55.0)

      (loop (a 0.0) (< a len) (+ a step)

            (set road-angle (+ road-angle (* step off)))

            (set prev-road-x road-x)
            (set prev-road-y road-y)
            (set road-x (+ road-x (* (cos road-angle) step)))
            (set road-y (+ road-y (* (sin road-angle) step)))

            -- 1 is on the left side
            (set x1 (- road-x (* -1.0 (sin road-angle) lane-width)))
            (set y1 (- road-y (* (cos road-angle) lane-width)))

            (set x2 (+ road-x (* -1.0 (sin road-angle) lane-width)))
            (set y2 (+ road-y (* (cos road-angle) lane-width)))

            (set xg1 (- road-x (* -1.0 (sin road-angle) 1.5 lane-width)))
            (set yg1 (- road-y (* (cos road-angle) 1.5 lane-width)))

            (set xg2 (+ road-x (* -1.0 (sin road-angle) 3.5 lane-width)))
            (set yg2 (+ road-y (* (cos road-angle) 3.5 lane-width)))

            (set list-a (add-to-list (list x1 y1) list-a))
            (set list-b (add-to-list (list x2 y2) list-b))
            (set list-c (add-to-list (list road-x road-y) list-c))

            (set list-ground (add-to-list (list xg1 yg1) list-ground))
            (set list-ground (add-to-list (list xg2 yg2) list-ground))
            (set list-road (add-to-list (list x1 y1) list-road))
            (set list-road (add-to-list (list x2 y2) list-road))

            (if (< (- line-length (* line-length-single (int (/ line-length line-length-single)) ))
                   (* 0.5 line-length-single))

              (do
                (set xlp1 (- prev-road-x (* -1.0 (sin road-angle) line-width)))
                (set ylp1 (- prev-road-y (* (cos road-angle) line-width)))

                (set xlp2 (+ prev-road-x (* -1.0 (sin road-angle) line-width)))
                (set ylp2 (+ prev-road-y (* (cos road-angle) line-width)))

                (set xl1 (- road-x (* -1.0 (sin road-angle) line-width)))
                (set yl1 (- road-y (* (cos road-angle) line-width)))

                (set xl2 (+ road-x (* -1.0 (sin road-angle) line-width)))
                (set yl2 (+ road-y (* (cos road-angle) line-width)))

                (set list-line (add-to-list (list xl2 yl2) list-line))
                (set list-line (add-to-list (list xl1 yl1) list-line))

                (set list-line (add-to-list (list xlp1 ylp1) list-line))
                (set list-line (add-to-list (list xlp2 ylp2) list-line))
                ))

            (set line-length (+ line-length step))
            )

      (set road (add-to-list (list list-ground list-road list-line list-a list-b list-c) road))
      (set list-a (list (list x1 y1)))
      (set list-b (list (list x2 y2)))
      (set list-c (list (list road-x road-y)))
      -- lists are reversed
      (set list-ground (list (list xg2 yg2) (list xg1 yg1)))
      (set list-road (list (list x2 y2) (list x1 y1)))

      (set list-line n)

      --(set road-angle (+ road-angle direction))
      )

--(print "Road " road "\n")

(set window-width 640)
(set window-height 480)

(function set-viewport (window width height)
          (set window-width width)
          (set window-height height)
          (glViewport 0 0 window-width window-height)
          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          (glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0)
          )

--(function key-pressed (window key scancode action mods)
--          (if (and (= key GLFW_KEY_C) (= action GLFW_PRESS))
--            (set camera (if (= camera 1) 0 1)))
--          (if (and (= key GLFW_KEY_ESCAPE) (= action GLFW_PRESS))
--            (set *should-quit* 1))
--          )

--(define-c-callback key-callback (symbol-function 'key-pressed))
--(glfwSetKeyCallback window (ccallback key-callback))

--(define-c-callback resize-callback (symbol-function 'set-viewport))
--(glfwSetFramebufferSizeCallback window (ccallback resize-callback))

(function draw-rectangle (x-center y-center w h)
          (glBegin GL_LINE_LOOP)
          (glVertex3d (+ 0.0 x-center (* -0.5 w)) (+ 0.0 y-center (* -0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* 0.5 w)) (+ 0.0 y-center (* -0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* 0.5 w)) (+ 0.0 y-center (* 0.5 h)) 0.0)
          (glVertex3d (+ 0.0 x-center (* -0.5 w)) (+ 0.0 y-center (* 0.5 h)) 0.0)
          (glEnd))

(function process-input (time-delta)
          (if *keyboard-state*
            (do
          (if (= (aget *keyboard-state* SDL_SCANCODE_UP) 1)
            (set input-accelerator 1.0)
            (if (= (aget *keyboard-state* SDL_SCANCODE_DOWN) 1)
              (set input-accelerator -1.0)
              (set input-accelerator 0.0)))

          (if steering-input (set steering-time (+ steering-time time-delta)))
          (set steering-amount (* 0.4 (+ 3.0 steering-time) time-delta))

          (if (= (aget *keyboard-state* SDL_SCANCODE_LEFT) 1)
            (do 
              (if (not steering-input) (set steering-input 1))
              (if (> input-steering 0.0)
                (set input-steering (- input-steering (* 2.5 steering-amount)))
                (set input-steering (- input-steering steering-amount))

                   ))

            (if (= (aget *keyboard-state* SDL_SCANCODE_RIGHT) 1)
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
          ))
          )

(function time-step (time-delta)

          (set car-angle (+ car-angle (* 0.005 car-v time-delta input-steering)))

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
          (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))

          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          --(glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0)
          (gluPerspective 60.0 (/ window-width window-height) 0.1 50000.0)

          (glMatrixMode GL_MODELVIEW)
          (glLoadIdentity)

          (glRotated 90.0 1.0 0.0 0.0)
          (glTranslated 0.0 0.0 80.0)

          (glColor3d 1.0 0.0 1.0)
          
          (glPushMatrix)
          (glRotated (* -180.0 (/ car-angle pi))  0.0 0.0 1.0)
          (glRotated 90.0 0.0 0.0 1.0)

          (glDisable GL_DEPTH_TEST)
          (glDepthMask GL_FALSE) -- disable writing to depth buffer for the sky (infinitely far)
          -- draw sky
          (const sky-r 1000.0)
          --(glPolygonMode GL_FRONT GL_LINE)
          --(glBegin GL_QUADS)
          --(loop (angle 0) (<= angle (* 2.0 pi)) (+ angle 0.5)

          --      (const angle-next (+ angle 0.5))
          --      (glColor3d 0.0 1.0 1.0)
          --      (glVertex3d (* sky-r (cos angle-next)) (* sky-r (sin angle-next)) -1200.0)
          --      (glVertex3d (* sky-r (cos angle)) (* sky-r (sin angle)) -1200.0)
          --      (glColor3d 1.0 0.0 1.0)
          --      (glVertex3d (* sky-r (cos angle)) (* sky-r (sin angle)) 40.0)
          --      (glVertex3d (* sky-r (cos angle-next)) (* sky-r (sin angle-next)) 40.0)
          --      )
          --(glEnd)
          --(glPolygonMode GL_FRONT GL_FILL)

          (glEnable GL_DEPTH_TEST)
          (glDepthMask GL_TRUE)

          (glTranslated (+ car-x) (+ car-y) 0.0)

          --(glEnable GL_LIGHTING)
          --(glEnable GL_COLOR_MATERIAL)
          --(glEnable GL_LIGHT0)

          (loop-list (seg road)

                     --(glPolygonMode GL_FRONT GL_LINE)
                     ---------------------------
                     -- draw fall on left
                     ---------------------------
                     (set c 0)
                     --(glColor3d 0.1 0.0 0.1)
                     (glColor3d 0.35 0.20 0.070)
                     (glBegin GL_TRIANGLE_STRIP)
                     (loop-list (p (first seg))
                                (if (= c 1)
                                  (do
                                    (glVertex3d (first p) (second p) 0.0) -- at the road
                                    (glVertex3d (first p) (second p) 1000.0) -- below
                                    )
                                  )
                                (set c (if (= c 0) 1 0))
                                )
                     (glEnd)


                     ---------------------------
                     -- draw dirt
                     ---------------------------
                     (glColor3d 0.5 0.25 0.1)
                     (glBegin GL_TRIANGLE_STRIP)
                     (loop-list (p (first seg))
                                (glVertex3d (first p) (second p) 0.0)
                                )
                     (glEnd)

                     --(glPolygonMode GL_FRONT GL_FILL)

                     ---------------------------
                     -- draw asphalt
                     ---------------------------
                     --(glColor3d 0.0 1.0 1.0)
                     (glColor3d 0.5 0.5 0.5)

                     --(glPolygonMode GL_FRONT GL_LINE)
                     (glBegin GL_TRIANGLE_STRIP)
                     (loop-list (p (second seg))
                                (glVertex3d (first p) (second p) -1.5)
                                )
                     (glEnd)
                     --(glPolygonMode GL_FRONT GL_FILL)

                     --(glBegin GL_LINE_STRIP)
                     --(loop-list (p (third seg))
                                  --      (glVertex3d (first p) (second p) 0.0)
                                  --      )
                     --(glEnd)
                     --(glBegin GL_LINE_STRIP)
                     --(loop-list (p (fourth seg))
                                  --      (glVertex3d (first p) (second p) 0.0)
                                  --      )
                     --(glEnd)

                     ---------------------------
                     -- draw line
                     ---------------------------

                     (glColor3d 0.9 0.9 0.9)

                     (glBegin GL_QUADS)
                     (loop-list (p (third seg))
                                (glVertex3d (first p) (second p) -2.5)
                                )
                     (glEnd)

                     --(set c 0)
                     --(glColor3d 1.0 1.0 0.0)
                     --(glBegin GL_LINE_STRIP)
                     --(loop-list (p (fifth seg))
                     --           (set c (+ c 1))
                     --           (if (> c 15)
                     --             --(glColor3d 0.0 0.0 0.0)
                     --             (glColor4d 0.0 0.0 0.0 0.0)
                     --             )
                     --           (if (> c 30)
                     --             (do (glColor3d 1.0 1.0 0.0)
                     --               (set c 0)))
                     --           (glVertex3d (first p) (second p) -2.0)
                     --           )
                     --(glEnd)

                     )

          (glPopMatrix)

          (glPushMatrix)

          --(glTranslated (* 0.5 window-width) (* 0.5 window-height) 0.0)
          --(glScaled 1.0 -1.0 1.0)

          -- draw sky

          --(glBegin GL_QUADS)
          --(glColor3d 0.0 0.0 1.0)
          --(glVertex3d 0.0 0.0 0.0)
          --(glVertex3d window-width 0.0 0.0)
          --(glColor3d 0.0 1.0 1.0)
          --(glVertex3d window-width (* 0.5 window-height) 0.0)
          --(glVertex3d 0.0 (* 0.5 window-height) 0.0)
          --(glEnd)

          -- draw road
          --(glBegin GL_LINES)
          --(glColor3d 0.9 0.5 0.0)
          --(loop (y (* 0.5 window-height)) (<= y window-height) (+ y 1)
                  --      (glVertex3d 0 y 0.0)
                  --      (glVertex3d 200 y 0.0)
                  --      )
          --(glEnd)

          --(draw-rectangle 0.0 0.0 50.0 24.0)
          --(draw-rectangle 0.0 0.0 50.0 24.0)

          (glPopMatrix)

          -- 2D drawing overlay
          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          (glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0)

          (glMatrixMode GL_MODELVIEW)
          (glLoadIdentity)

          -- draw controls
          (glColor3d 0.0 0.0 1.0)
          (draw-rectangle (+ (* 0.5 window-width) (* input-steering 0.5 window-width)) 30.0 20.0 20.0)

          (glColor3d 1.0 1.0 0.5)
          (draw-rectangle 30.0 (- (* 0.5 window-height) (* input-accelerator 0.5 window-height)) 20.0 20.0)

          (glColor3d 1.0 0.3 0.0)
          (glPushMatrix)
          (glTranslated (+ (* 0.5 window-width) -60.0) (- window-height 50.0) 0)
          --(draw-rectangle 0.0 0.0 50.0 50.0)
          --(draw-instrument 50.0 0.0 2000.0 car-v)
          (glPopMatrix)

          (glColor3d 1.0 0.3 0.0)
          (glPushMatrix)
          (glTranslated (+ (* 0.5 window-width) 60.0) (- window-height 50.0) 0)
          --(draw-instrument 50.0 0.0 7000.0 car-rpm)
          (glPopMatrix)


          )

(function main-loop ()
          (set new-time (get-time))
          (set time-delta (- new-time *time*))
          (set *time* new-time)

          (process-input time-delta)
          (time-step time-delta)
          (render)

          (SDL_GL_SwapWindow *window*)

          (process-lisp))

(function main ()
          (SDL_Init SDL_INIT_VIDEO)
          --(SDL_GL_SetAttribute SDL_GL_MULTISAMPLEBUFFERS 1)
          --(SDL_GL_SetAttribute SDL_GL_MULTISAMPLESAMPLES 4)
          (set *window* (SDL_CreateWindow "Drive\0" 
                                          SDL_WINDOWPOS_UNDEFINED SDL_WINDOWPOS_UNDEFINED
                                          window-width window-height (+ SDL_WINDOW_OPENGL SDL_WINDOW_RESIZABLE)))

          (set *context* (SDL_GL_CreateContext *window*))
          (print "Context " *context* "\n")

          (set-viewport *window* window-width window-height)


          (set tmp (make-array 1 'i32))

          (set ptr (SDL_GetKeyboardState (buffer-pointer tmp)))
          (if (= ptr 0)
            (do
              (print "SDL_GetKeyboardState returned NULL\n")
              (SDL_Quit)
              (quit 1)))

          (set *keyboard-state* (array-view-from-pointer 'u8 (aget tmp 0) ptr))

          (glViewport 0 0 640 480)
          (glClearColor 0.0 0.0 0.0 1.0)

          (set event-buf (make-array 14 'u32))  -- sizeof is 56

          (while (= *should-quit* n)
                 -- process events
                 (while (> (SDL_PollEvent (buffer-pointer event-buf)) 0)
                        (set ev-type (aget event-buf 0))
                        --(print "Event received, type " ev-type " " (hex ev-type) "\n")

                        (if (= ev-type SDL_QUIT)
                          (set *should-quit* 1))

                        (if (= ev-type SDL_WINDOWEVENT)
                          (do
                            (set a1 (make-array 2 'i32))
                            (SDL_GetWindowSize *window* (buffer-pointer a1) (+ 4 (buffer-pointer a1)))
                            (if (or (not (= window-width (aget a1 0)))
                                    (not (= window-height (aget a1 1))))
                              (do
                                (set window-width (aget a1 0))
                                (set window-height (aget a1 1))
                                --(print "new window size " window-width " " window-height "\n")
                                (set-viewport *window* window-width window-height)
                                ))
                            ))
                        )

                 (main-loop))

          (SDL_Quit)
          (quit)
          )


(main)

