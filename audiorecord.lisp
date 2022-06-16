(load "portaudio.lisp")
(load "glfw.lisp")
(load "opengl.lisp")

(set window-width 640)
(set window-height 480)
(set should-quit n)
(set window n)
(set *samplerate* 44100)
(set *num-in-channels* 2)
(set recording-active n)
(set recording-buffers (make-array (* 24 3600)))
(set recording-buffers-count 0)
(set recording-buffer-size (* *samplerate* *num-in-channels*))

(set recording-overview-buffers (make-array (* 24 3600)))
(set recording-overview-division 10)
(set preview-div (make-array 6))
(set preview-count (make-array 6))
(aset preview-div 0 10)
(aset preview-div 1 100)
(aset preview-div 2 1000)
(aset preview-div 3 10000)
(aset preview-div 4 100000)
(aset preview-div 5 (/ recording-buffer-size *num-in-channels*))
(set preview-off (make-array 6))
(loop (i 0) (< i 6) (+ i 1)
      (aset preview-count i (int (ceil (/ (/ recording-buffer-size *num-in-channels*) (aget preview-div i)))))
      (aset preview-off i
            (if (= i 0) 0
              (int (+ (aget preview-off (- i 1))

                 (* *num-in-channels* 2 (ceil (/ (/ recording-buffer-size *num-in-channels*) (aget preview-div (- i 1)))))

                 ))
              )))
(set recording-overview-buffer-size (int (aget preview-off 5)))

(print preview-off)

(set samples-per-px 500.0)
(set waveview-position 0)
(set play-position 0)

(set recording-position 0)
(set last-buffer-in-pos 0)

(set amplitude-l 0.0)
(set amplitude-r 0.0)

(set buffer-in-size (* 2 1024 1024))
(set buffer-in (make-array buffer-in-size 'i16))
(set buffer-in-pos 0)

(set buffer-out-size (* 2 1024 1024))
(set buffer-out (make-array buffer-out-size 'i16))
(set buffer-out-pos 0)

(function int-to-bytes (x)
          (list (bit-and x 0xff)
            (bit-shift (bit-and x 0xff00) -8)
            (bit-shift (bit-and x 0xff0000) -16)
            (bit-shift (bit-and x 0xff000000) -24)))

(function i16-to-bytes (x)
          (list (bit-and x 0xff)
            (bit-shift (bit-and x 0xff00) -8)))

(function write-wav-header (file sample-rate bit-depth channel-count)
          (write file "RIFF")
          (write file "    ") -- placeholder for length
          (write file "WAVE")
          (write file "fmt ")
          (write file '(0x10 0 0 0)) -- length of fmt_ chunk
          (write file '(0x01 0))
          (write file (i16-to-bytes channel-count)) -- channel number
          (write file (int-to-bytes sample-rate)) -- sample rate
          (write file (int-to-bytes (* sample-rate (/ bit-depth 8) channel-count))) -- bytes per second
          (write file (i16-to-bytes (* (/ bit-depth 8) channel-count))) -- bytes per sample
          (write file (i16-to-bytes bit-depth)) -- bits per sample

          (write file "data")
          (write file "    ") -- placeholder for length
          )

(function finish-wav-file (file)
          (set total-length (seek file))
          (print "Wav file total lenght " total-length " " (hex total-length) "\n")
          -- write length
          (seek file 40)
          (write file (int-to-bytes (- total-length 44)))

          (set full-byte-count (- total-length  8))
          (seek file 4)
          (write file (int-to-bytes full-byte-count))
          (close file))

(function amplitude-to-log (x)
          (/ (+ 3.0 (/ (log x) (log 10))) 3.0))

(function max (x y) (if (> x y) x y))
(function min (x y) (if (< x y) x y))

(function sound-callback (input output frameCount timeInfo statusFlags userData)
          --(print "Sound callback \n")
          --(print "frame count: " frameCount "\n")
          --(print "input " (hex input) "\n")
          (set sample-count (* 2 frameCount))
          (set av (array-view-from-pointer 'i16 sample-count input))

          (set free-count (- buffer-in-size buffer-in-pos))

          (if (< free-count sample-count)
            (do
              -- double copy
              (memory-copy av 0 buffer-in buffer-in-pos free-count)
              (memory-copy av free-count buffer-in 0 (- sample-count free-count))
              (set buffer-in-pos (- sample-count free-count))
              )
            (do
              -- single copy
              (memory-copy av 0 buffer-in buffer-in-pos sample-count)
              (set buffer-in-pos (+ buffer-in-pos sample-count))
              (if (= buffer-in-pos buffer-in-size) (set buffer-in-pos 0))
              ))

          (if (not (= output 0))
            (do
              -- output
              (set av-out (array-view-from-pointer 'i16 sample-count output))

              (if (> (+ buffer-out-pos sample-count) buffer-out-size)
                (do
                  (set element-count (- buffer-out-size buffer-out-pos))
                  -- double copy
                  (memory-copy buffer-out buffer-out-pos av-out 0 element-count)
                  (memory-copy buffer-out 0 av-out element-count (- sample-count element-count))
                  (set buffer-out-pos (- sample-count element-count))
                  )
                (do
                  -- single copy
                  (memory-copy buffer-out buffer-out-pos av-out 0 sample-count)
                  (set buffer-out-pos (+ buffer-out-pos sample-count))
                  (if (= buffer-out-pos buffer-out-size) (set buffer-out-pos 0))
                  ))
              ))

          paContinue
          )

(function set-viewport (window width height)
          (set window-width width)
          (set window-height height)
          (glViewport 0 0 window-width window-height)
          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          (glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0))

(function toggle-recording ()
          (set recording-active (not recording-active)))

(function key-pressed (window key scancode action mods)
          (if (and (= key GLFW_KEY_ESCAPE) (= action GLFW_PRESS))
            (set should-quit 1))

          (if (and (= key GLFW_KEY_R) (= action GLFW_PRESS))
            (toggle-recording))
          )

(function draw-rectangle (x-center y-center w h)
          (glBegin GL_LINE_LOOP)
          (glVertex3d (+ -0.5 x-center) (+ -0.5 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glEnd))

(function draw-filled-rectangle (x-center y-center w h)
          (glBegin GL_QUADS)
          (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glEnd))

(function draw-button (pos x-center y-center w h)
          (glColor3d 0.4 0.4 0.4)
          (glBegin GL_QUADS)
          (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 0.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 1.0 h)) 0.0)
          (glEnd)

          (if (> pos 0)
            (do
              (glColor3d 0.3 0.3 0.3)
              (glBegin GL_LINES)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glEnd)

              (glColor3d 0.7 0.7 0.7)
              (glBegin GL_LINES)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center w) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 1.0 h)) 0.0)
              (glEnd)
              )
            (do
              (glColor3d 0.3 0.3 0.3)
              (glBegin GL_LINES)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center w) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.5 x-center) (+ 0.5 y-center (* 1.0 h)) 0.0)
              (glEnd)
              (glColor3d 0.7 0.7 0.7)
              (glBegin GL_LINES)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 0.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glVertex3d (+ 0.0 x-center w) (+ 0.0 y-center (* 1.0 h)) 0.0)
              (glEnd)
              ))
          )

(function draw-filled-circle (x-center y-center w h)
          (set s2 30.0)
          (glBegin GL_TRIANGLES)
          (loop (tmp 0.0) (< tmp 360.0) (+ tmp s2)
                (set alpha (* (/ tmp 180.0) pi))
                (set alpha2 (* (/ (+ tmp s2) 180.0) pi))
                (glVertex3d x-center y-center 0.0)
                (glVertex3d (+ 0.0 x-center (* w (cos alpha))) (+ 0.0 y-center (* h (sin alpha))) 0.0)
                (glVertex3d (+ 0.0 x-center (* w (cos alpha2))) (+ 0.0 y-center (* h (sin alpha2))) 0.0)
                )
          (glEnd))

(function sample-to-screen (s)
          (/ (- s waveview-position) samples-per-px))

(function render ()
          (glClear GL_COLOR_BUFFER_BIT)
          (glMatrixMode GL_MODELVIEW)
          (glLoadIdentity)

          --(glTranslated (* 0.5 window-width) (* 0.5 window-height) 0.0)
          --(glScaled 1.0 -1.0 1.0)

          (glColor3d 0.8 0.8 0.8)
          (set overview-width window-width)
          (if (> recording-buffers-count 0)
            (do
              (set overview-level -1)
              (loop (ipre 0) (< ipre 5) (+ ipre 1)
                    (if (> (* samples-per-px 2.0) (aget preview-div ipre))
                      (set overview-level ipre)))

              --(print "overview level " overview-level "\n")
              (glColor3d 0.7 0.7 1.0)

              (set preview-y 150)
              (set preview-y-scale (* 150 (/ 1.0 32768.0)))

              (set start-sample (* *num-in-channels* waveview-position))
              (set end-sample (* *num-in-channels* (+ waveview-position (* samples-per-px overview-width))))

              (set start-arr-idx (int/ start-sample recording-buffer-size))
              (set end-arr-idx (min (int/ end-sample recording-buffer-size) (- recording-buffers-count 1)))

              (set div (aget preview-div overview-level))
              (set off (aget preview-off overview-level))
              (set x-delta (/ (aget preview-div overview-level) samples-per-px))

              --(print "start end " start-arr-idx " " end-arr-idx "\n")
              --(print "buffers " recording-overview-buffers "\n")

              (glBegin GL_LINES)
              (loop (iarr start-arr-idx) (<= iarr end-arr-idx) (+ iarr 1)
                    (set arr (aget recording-overview-buffers iarr))

                    (set start-idx (if (< start-sample (* iarr recording-buffer-size))
                                     0
                                     (int/ (mod start-sample recording-buffer-size) (* *num-in-channels* div))))

                    (set end-idx (if (> end-sample (* (+ 1 iarr) recording-buffer-size))
                                   (aget preview-count overview-level)
                                   (int/ (mod end-sample recording-buffer-size) (* *num-in-channels* div))))

                    (set x-off (/ (- (/ (* iarr recording-buffer-size) *num-in-channels*) waveview-position) samples-per-px))

              --(print "start end 2 " start-idx " " end-idx " div " div "\n")

              (loop (pt start-idx) (< pt end-idx) (+ pt 1)

                    (glVertex3d (+ x-off (* x-delta pt)) (+ preview-y) 0.0)
                    (glVertex3d (+ x-off (* x-delta pt)) (+ preview-y (* -1.0 preview-y-scale (aget arr (+ off (* 4 pt))))) 0.0)

                    (glVertex3d (+ x-off (* x-delta pt)) (+ preview-y) 0.0)
                    (glVertex3d (+ x-off (* x-delta pt)) (+ preview-y (* -1.0 preview-y-scale (aget arr (+ off 1 (* 4 pt))))) 0.0)

                    )

                    )
              (glEnd)
              ))

          (glColor3d 1.0 0.2 0.2)
              (glBegin GL_LINES)
              (glVertex3d (sample-to-screen (/ recording-position *num-in-channels*)) 0.0 0.0)
              (glVertex3d (sample-to-screen (/ recording-position *num-in-channels*)) (- window-height 50.0) 0.0)
              (glEnd)

          (set x-origin (list 0.0))
          (set y-origin (list 0.0))

          (set x-max (list window-width))
          (set y-max (list window-height))


          -- draw meter
          (glColor3d 0.8 0.8 0.8)

          (set meter-width 50.0)

          (push (+ (first x-origin) (- window-width meter-width)) x-origin)
          (push (+ (first y-origin) 1.0) y-origin)

          (draw-rectangle (first x-origin) (first y-origin) meter-width (- window-height 1.0))

          (glColor3d 0.8 0.0 0.0)

          (set margin 8.0)
          (push (+ (first x-origin) margin) x-origin)
          (push (+ (first y-origin) margin) y-origin)

          (push (- (first x-max) margin) x-max)
          (push (- (first y-max) margin) y-max)

          (set bar-height (- (first y-max) (first y-origin)))

          (set bar-real-height (* bar-height amplitude-l))

          (draw-filled-rectangle (first x-origin) (+ (first y-origin) (- bar-height bar-real-height))
                                 (- (first x-max) (first x-origin)) bar-real-height)

          (pop x-origin)
          (pop y-origin)
          (pop x-origin)
          (pop y-origin)
          (pop x-max)
          (pop y-max)

          (set widget-width 70)

          (glColor3d 0.1 0.1 0.1)

          (draw-filled-rectangle (first x-origin) (+ (first y-origin) (- window-height widget-width))
                                 (- (first x-max) (first x-origin) meter-width 1) (- (first y-max) (first y-origin)))

          (push (- (* 0.5 window-width) (* 0.5 widget-width)) x-origin)
          (push (- window-height widget-width) y-origin)

          (push (+ (* 0.5 window-width) (* 0.5 widget-width)) x-max)
          (push window-height y-max)

          (draw-button (if recording-active 0 1) (first x-origin) (first y-origin)
                                 (- (first x-max) (first x-origin)) (- (first y-max) (first y-origin)))

          (glColor3d 0.7 0.1 0.1)
          (draw-filled-circle (* 0.5 (+ (first x-origin) (first x-max) (if recording-active 2 0))) (* 0.5 (+ (first y-origin) (first y-max) (if recording-active 2 0))) 15.0 15.0)
          )

(function allocate-new-recording-buffer ()
          (print "Allocating new recording buffer idx " recording-buffers-count "\n")
          (aset recording-buffers recording-buffers-count (make-array recording-buffer-size 'i16))
          (aset recording-overview-buffers recording-buffers-count (make-array recording-overview-buffer-size 'i16))
          (print recording-buffers " rec buf \n")
          (print recording-overview-buffers " rec over buf \n")

          (set recording-buffers-count (+ recording-buffers-count 1)))

(function process-audio (time-delta)
          -- update meters
          (set amplitude-l (- amplitude-l (* 1.5 time-delta amplitude-l)))
          (set amplitude-r (- amplitude-r (* 1.5 time-delta amplitude-r)))

          -- update with new data from recording thread etc.
          (if (not (= last-buffer-in-pos buffer-in-pos))
            (do 
              (set new-buffer-in-pos buffer-in-pos)
              -- copy data
              (set amp-l 0.0)
              (set amp-r 0.0)

              (set preview-data (make-array (* 2 2 5) 'f64))

              (if (< new-buffer-in-pos last-buffer-in-pos)
                (do
                  -- process in two parts
                  (print "Two parts last pos " last-buffer-in-pos " new pos " new-buffer-in-pos " diff " (+ new-buffer-in-pos (- buffer-in-size last-buffer-in-pos)) "\n")

                  (loop (i last-buffer-in-pos) (< i buffer-in-size) (+ 2 i)
                        (set sample-l (aget buffer-in i))
                        (set sample-r (aget buffer-in (+ i 1)))

                        (set amp-l (max amp-l (abs sample-l)))
                        (set amp-r (max amp-r (abs sample-r)))

                        (if recording-active
                          (do
                            (if (>= (/ (+ recording-position 2) recording-buffer-size)
                                    recording-buffers-count)
                              (allocate-new-recording-buffer))

                            (set arr (aget recording-buffers (int/ recording-position recording-buffer-size)))
                            (set relative-idx (mod recording-position recording-buffer-size))

                            (aset arr relative-idx sample-l)
                            (aset arr (+ relative-idx 1) sample-r)
                                  
                            (set preview-arr (aget recording-overview-buffers (int/ recording-position recording-buffer-size)))

                            (loop (ipre 0) (< ipre 5) (+ ipre 1)
                                  (set pre-idx (+ (aget preview-off ipre) (* 4 (int/ (int/ relative-idx *num-in-channels*) (aget preview-div ipre)))))

                                  (aset preview-arr pre-idx (max (aget preview-arr pre-idx) sample-l))
                                  (aset preview-arr (+ pre-idx 1) (min (aget preview-arr (+ pre-idx 1)) sample-l))

                                  (aset preview-arr (+ pre-idx 2) (max (aget preview-arr (+ pre-idx 2)) sample-r))
                                  (aset preview-arr (+ pre-idx 3) (min (aget preview-arr (+ pre-idx 3)) sample-r))
                                  )
                            (set recording-position (+ recording-position 2))
                            ))
                        )

                  (loop (i 0) (< i new-buffer-in-pos) (+ 2 i)
                        (set sample-l (aget buffer-in i))
                        (set sample-r (aget buffer-in (+ i 1)))

                        (set amp-l (max amp-l (abs sample-l)))
                        (set amp-r (max amp-r (abs sample-r)))

                        (if recording-active
                          (do
                            (if (>= (/ (+ recording-position 2) recording-buffer-size)
                                    recording-buffers-count)
                              (allocate-new-recording-buffer))

                            (set arr (aget recording-buffers (int/ recording-position recording-buffer-size)))
                            (set relative-idx (mod recording-position recording-buffer-size))

                            (aset arr relative-idx sample-l)
                            (aset arr (+ relative-idx 1) sample-r)
                                  
                            (set preview-arr (aget recording-overview-buffers (int/ recording-position recording-buffer-size)))

                            (loop (ipre 0) (< ipre 5) (+ ipre 1)
                                  (set pre-idx (+ (aget preview-off ipre) (* 4 (int/ (int/ relative-idx *num-in-channels*) (aget preview-div ipre)))))

                                  (aset preview-arr pre-idx (max (aget preview-arr pre-idx) sample-l))
                                  (aset preview-arr (+ pre-idx 1) (min (aget preview-arr (+ pre-idx 1)) sample-l))

                                  (aset preview-arr (+ pre-idx 2) (max (aget preview-arr (+ pre-idx 2)) sample-r))
                                  (aset preview-arr (+ pre-idx 3) (min (aget preview-arr (+ pre-idx 3)) sample-r))
                                  )
                            (set recording-position (+ recording-position 2))
                            ))
                        )

                  )
                (do
                  --(print "One part last pos " last-buffer-in-pos " new pos " new-buffer-in-pos " diff " (- new-buffer-in-pos last-buffer-in-pos) "\n")

                  (loop (i last-buffer-in-pos) (< i new-buffer-in-pos) (+ 2 i)
                        (set sample-l (aget buffer-in i))
                        (set sample-r (aget buffer-in (+ i 1)))

                        (set amp-l (max amp-l (abs sample-l)))
                        (set amp-r (max amp-r (abs sample-r)))

                        (if recording-active
                          (do
                            (if (>= (/ (+ recording-position 2) recording-buffer-size)
                                    recording-buffers-count)
                              (allocate-new-recording-buffer))

                            (set arr (aget recording-buffers (int/ recording-position recording-buffer-size)))
                            (set relative-idx (mod recording-position recording-buffer-size))

                            (aset arr relative-idx sample-l)
                            (aset arr (+ relative-idx 1) sample-r)
                                  
                            (set preview-arr (aget recording-overview-buffers (int/ recording-position recording-buffer-size)))

                            (loop (ipre 0) (< ipre 5) (+ ipre 1)
                                  (set pre-idx (+ (aget preview-off ipre) (* 4 (int/ (int/ relative-idx *num-in-channels*) (aget preview-div ipre)))))

                                  (aset preview-arr pre-idx (max (aget preview-arr pre-idx) sample-l))
                                  (aset preview-arr (+ pre-idx 1) (min (aget preview-arr (+ pre-idx 1)) sample-l))

                                  (aset preview-arr (+ pre-idx 2) (max (aget preview-arr (+ pre-idx 2)) sample-r))
                                  (aset preview-arr (+ pre-idx 3) (min (aget preview-arr (+ pre-idx 3)) sample-r))
                                  )
                            (set recording-position (+ recording-position 2))
                            ))
                        )
                  --(if recording-active (do (write out-file av)))
                  )
                )

              (set tmp-amp (/ amp-l 32768.0))
              (set amplitude-l (max (amplitude-to-log tmp-amp) amplitude-l))
              (set tmp-amp (/ amp-r 32768.0))
              (set amplitude-r (max (amplitude-to-log tmp-amp) amplitude-r))


              (set last-buffer-in-pos new-buffer-in-pos)
              ))

          )

(function process-input (time-delta)
          (set factor (if (or (= (glfwGetKey window GLFW_KEY_LEFT_SHIFT) GLFW_PRESS)
                              (= (glfwGetKey window GLFW_KEY_RIGHT_SHIFT) GLFW_PRESS))
                        10.0 5.0))
          (if (= (glfwGetKey window GLFW_KEY_UP) GLFW_PRESS)
            (set samples-per-px (* 0.9 samples-per-px)))

          (if (= (glfwGetKey window GLFW_KEY_DOWN) GLFW_PRESS)
            (set samples-per-px (* 1.1 samples-per-px)))

          (if (= (glfwGetKey window GLFW_KEY_LEFT) GLFW_PRESS)
            (set waveview-position (max 0 (- waveview-position (* factor samples-per-px)))))

          (if (= (glfwGetKey window GLFW_KEY_RIGHT) GLFW_PRESS)
            (set waveview-position (+ waveview-position (* factor samples-per-px)))))

(set time (get-time))

(function main-loop ()
          (set new-time (get-time))
          (set time-delta (- new-time time))

          (process-input time-delta)
          (process-audio time-delta)
          (render)

          (set time new-time)

          (glfwSwapBuffers window)
          (glfwPollEvents)
          (process-lisp))

(set stream n)

(function init-audio ()
          (define-c-callback pa-callback (symbol-function 'sound-callback))

          (Pa_Initialize)
          (set str (make-array 1 'u64))
          --(Pa_OpenDefaultStream str 2 0 paInt16 44100.0 512 (ccallback pa-callback) 0)

          (set in-param (make-array 32 'u8))

          (loop (i 0) (< i 32) (+ i 1)
                (aset in-param i 0))

          (aset in-param 4 2)
          (aset in-param 8 8)

          (set out-param (make-array 32 'u8))

          (loop (i 0) (< i 32) (+ i 1)
                (aset out-param i 0))

          (aset out-param 4 2)
          (aset out-param 8 8)

          --(Pa_OpenStream str in-param 0 *samplerate* 512 0 (ccallback pa-callback) 0)
          (Pa_OpenStream str in-param out-param *samplerate* 512 0 (ccallback pa-callback) 0)

          (set stream (aget str 0))

          (print "Stream ptr: " (hex stream) "\n")
          )

(function main ()

          (glfwInit)
          (glfwSwapInterval 1)

          (init-audio)

          (Pa_StartStream stream)

          (set window (glfwCreateWindow window-width window-height "Audio Record\0" 0 0))

          (glfwMakeContextCurrent window)

          (set-viewport window window-width window-height)

          (define-c-callback key-callback (symbol-function 'key-pressed))
          (glfwSetKeyCallback window (ccallback key-callback))

          (define-c-callback resize-callback (symbol-function 'set-viewport))
          (glfwSetFramebufferSizeCallback window (ccallback resize-callback))


          (while (and (= (glfwWindowShouldClose window) 0) (= should-quit n))
                 (main-loop))

          (Pa_StopStream stream)
          (glfwDestroyWindow window)
          (glfwTerminate)
          (quit 0)

          --(set out-file (open "test.wav" 1))
          --(write-wav-header out-file 44100 16 2)
          --(finish-wav-file out-file)

          )

(main)

