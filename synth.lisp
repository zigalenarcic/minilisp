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
(set recording-buffers (array 'obj (* 24 3600)))
(set recording-buffers-count 0)
(set recording-buffer-size (* *samplerate* *num-in-channels*))

(set key-input (array 'obj 17))

(set recording-overview-buffers (array 'obj (* 24 3600)))
(set recording-overview-division 10)
(set preview-div (array 'obj 6))
(set preview-count (array 'obj 6))
(aset preview-div 0 10)
(aset preview-div 1 100)
(aset preview-div 2 1000)
(aset preview-div 3 10000)
(aset preview-div 4 100000)
(aset preview-div 5 (/ recording-buffer-size *num-in-channels*))
(set preview-off (array 'obj 6))
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
(set buffer-in (array 'i16 buffer-in-size))
(set buffer-in-pos 0)

(set buffer-out-size (* 2 1024 1024))
(set buffer-out (array 'i16 buffer-out-size))
(set buffer-out-pos 0)
(set buffer-out-write-pos 0)

(function circular-distance (x1 x2 period)
          (if (>= x2 x1) (- x2 x1)
            (- (+ x1 period) x2)))

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

          (if (not (= output 0))
            (do
              -- output
              (set av-out (array-view-ptr 'i16 sample-count output))

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
              )
            )

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

(set octave 4)

-- note 57 is A4 (4 * 12 + 9)
(function note-freq (note)
          (* 440.0 (pow 2.0 (/ (- note 57) 12))))

(function key-pressed (window key scancode action mods)
          (if (and (= key GLFW_KEY_ESCAPE) (= action GLFW_PRESS))
            (set should-quit 1))
          (if (and (= key GLFW_KEY_Q) (= action GLFW_PRESS))
            (set should-quit 1))

          (if (and (= key GLFW_KEY_LEFT (= action GLFW_PRESS)))
            (set octave (- octave 1)))
          (if (and (= key GLFW_KEY_RIGHT (= action GLFW_PRESS)))
            (set octave (+ octave 1)))
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

(function draw-key (x-off y-off w h pressed)
          (if pressed
            (glColor3d 0.5 0.5 0.5)
            (glColor3d 0.7 0.7 0.7))
          (draw-filled-rectangle x-off y-off w h)
          (glColor3d 0.2 0.2 0.2)
          (draw-rectangle x-off y-off w h))

(function draw-key-black (x-off y-off w h pressed)
          (if pressed
            (glColor3d 0.3 0.3 0.3)
            (glColor3d 0.1 0.1 0.1))
          (draw-filled-rectangle x-off y-off w h)
          (glColor3d 0.2 0.2 0.2)
          (draw-rectangle x-off y-off w h))

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


          (set off-x 20)
          (set off-y 200)
          (set key-width 20)
          (set key-height 100)

          (draw-key (+ off-x (* 0 key-width)) off-y key-width key-height (aget key-input 0))
          (draw-key (+ off-x (* 1 key-width)) off-y key-width key-height (aget key-input 2))
          (draw-key (+ off-x (* 2 key-width)) off-y key-width key-height (aget key-input 4))

          (draw-key (+ off-x (* 3 key-width)) off-y key-width key-height (aget key-input 5))
          (draw-key (+ off-x (* 4 key-width)) off-y key-width key-height (aget key-input 7))
          (draw-key (+ off-x (* 5 key-width)) off-y key-width key-height (aget key-input 9))
          (draw-key (+ off-x (* 6 key-width)) off-y key-width key-height (aget key-input 11))

          (draw-key (+ off-x (* 7 key-width)) off-y key-width key-height (aget key-input 12))
          (draw-key (+ off-x (* 8 key-width)) off-y key-width key-height (aget key-input 14))
          (draw-key (+ off-x (* 9 key-width)) off-y key-width key-height (aget key-input 16))

          (draw-key-black (+ off-x (* 0.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 1))
          (draw-key-black (+ off-x (* 1.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 3))

          (draw-key-black (+ off-x (* 3.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 6))
          (draw-key-black (+ off-x (* 4.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 8))
          (draw-key-black (+ off-x (* 5.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 10))

          (draw-key-black (+ off-x (* 7.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 13))
          (draw-key-black (+ off-x (* 8.625 key-width)) off-y (* 0.75 key-width) (* 0.6 key-height) (aget key-input 15))

          )

(function allocate-new-recording-buffer ()
          (print "Allocating new recording buffer idx " recording-buffers-count "\n")
          (aset recording-buffers recording-buffers-count (array 'i16 recording-buffer-size))
          (aset recording-overview-buffers recording-buffers-count (array 'i16 recording-overview-buffer-size))
          (print recording-buffers " rec buf \n")
          (print recording-overview-buffers " rec over buf \n")

          (set recording-buffers-count (+ recording-buffers-count 1)))

(set audio-frame 0)

(function process-audio (time-delta)
          -- update meters
          (set amplitude-l (- amplitude-l (* 1.5 time-delta amplitude-l)))
          (set amplitude-r (- amplitude-r (* 1.5 time-delta amplitude-r)))

          -- update with new data from recording thread etc.
          
          (set freqs (array 'f64 17))
          (set period (array 'obj 17))
          (loop (j 0) (< j 17) (+ j 1)
                (aset freqs j (note-freq (+ (* octave 12) j)))
                (aset period j (int (round (/ *samplerate* (aget freqs j)))))
                )

          (set num-samples (- (* 8 1024) (circular-distance buffer-out-pos buffer-out-write-pos buffer-out-size)))
          (if (< num-samples 0)
            (set num-samples (* 16 1024)))

          --(print "num samples " num-samples " bufferout pos " buffer-out-pos " buffer-out-write-pos " buffer-out-write-pos "\n")

          (if (>= (+ buffer-out-write-pos num-samples) buffer-out-size)
            (do
              (set remaining-samples (- (+ buffer-out-write-pos num-samples) buffer-out-size))

              (loop (i 0) (< i (/ (- buffer-out-size buffer-out-write-pos) 2)) (+ i 1)
                    (set audio-frame (+ audio-frame 1))
                    (set val 0)
                    (loop (j 0) (< j 17) (+ j 1)
                          (if (aget key-input j)
                            (set val (+ val (* 10000 (if (> (mod audio-frame (aget period j)) (/ (aget period j) 2)) 1 -1))))
                            )
                          )
                    (aset buffer-out (+ buffer-out-write-pos (* 2 i)) val) -- stereo
                    (aset buffer-out (+ buffer-out-write-pos (* 2 i) 1) val)
                    )
              (loop (i 0) (< i (/ remaining-samples 2)) (+ i 1)
                    (set audio-frame (+ audio-frame 1))
                    (set val 0)
                    (loop (j 0) (< j 17) (+ j 1)
                          (if (aget key-input j)
                            (set val (+ val (* 10000 (if (> (mod audio-frame (aget period j)) (/ (aget period j) 2)) 1 -1))))
                            )
                          )
                    (aset buffer-out (+ (* 2 i)) val) -- stereo
                    (aset buffer-out (+ (* 2 i) 1) val)
                    )

              (set buffer-out-write-pos remaining-samples)
              )
            (do
              (loop (i 0) (< i (/ num-samples 2)) (+ i 1)
                    (set audio-frame (+ audio-frame 1))
                    (set val 0)
                    (loop (j 0) (< j 17) (+ j 1)
                          (if (aget key-input j)
                            (set val (+ val (* 10000 (if (> (mod audio-frame (aget period j)) (/ (aget period j) 2)) 1 -1))))
                            )
                          )
                    (aset buffer-out (+ buffer-out-write-pos (* 2 i)) val) -- stereo
                    (aset buffer-out (+ buffer-out-write-pos (* 2 i) 1) val)
                    )

              (set buffer-out-write-pos (+ buffer-out-write-pos num-samples))
              ))

          )

(function process-input (time-delta)
          (aset key-input 0 (= (glfwGetKey window GLFW_KEY_A) GLFW_PRESS))
          (aset key-input 1 (= (glfwGetKey window GLFW_KEY_W) GLFW_PRESS))
          (aset key-input 2 (= (glfwGetKey window GLFW_KEY_S) GLFW_PRESS))
          (aset key-input 3 (= (glfwGetKey window GLFW_KEY_E) GLFW_PRESS))
          (aset key-input 4 (= (glfwGetKey window GLFW_KEY_D) GLFW_PRESS))
          (aset key-input 5 (= (glfwGetKey window GLFW_KEY_F) GLFW_PRESS))
          (aset key-input 6 (= (glfwGetKey window GLFW_KEY_T) GLFW_PRESS))
          (aset key-input 7 (= (glfwGetKey window GLFW_KEY_G) GLFW_PRESS))
          (aset key-input 8 (= (glfwGetKey window GLFW_KEY_Y) GLFW_PRESS))
          (aset key-input 9 (= (glfwGetKey window GLFW_KEY_H) GLFW_PRESS))
          (aset key-input 10 (= (glfwGetKey window GLFW_KEY_U) GLFW_PRESS))
          (aset key-input 11 (= (glfwGetKey window GLFW_KEY_J) GLFW_PRESS))
          (aset key-input 12 (= (glfwGetKey window GLFW_KEY_K) GLFW_PRESS))
          (aset key-input 13 (= (glfwGetKey window GLFW_KEY_O) GLFW_PRESS))
          (aset key-input 14 (= (glfwGetKey window GLFW_KEY_L) GLFW_PRESS))
          (aset key-input 15 (= (glfwGetKey window GLFW_KEY_P) GLFW_PRESS))
          (aset key-input 16 (= (glfwGetKey window GLFW_KEY_SEMICOLON) GLFW_PRESS))
          )

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
          (set str (array 'u64 1))
          --(Pa_OpenDefaultStream str 2 0 paInt16 44100.0 512 (ccallback pa-callback) 0)
          (Pa_OpenDefaultStream str 0 2 paInt16 44100.0 512 (ccallback pa-callback) 0)

          -- (set in-param (array 'u8 32))

          -- (loop (i 0) (< i 32) (+ i 1)
          --       (aset in-param i 0))

          -- (aset in-param 4 2)
          -- (aset in-param 8 8)

          -- (set out-param (array 'u8 32))

          -- (loop (i 0) (< i 32) (+ i 1)
          --       (aset out-param i 0))

          -- (aset out-param 4 2)
          -- (aset out-param 8 8)

          -- --(Pa_OpenStream str in-param 0 *samplerate* 512 0 (ccallback pa-callback) 0)
          -- --(Pa_OpenStream str in-param out-param *samplerate* 512 0 (ccallback pa-callback) 0)
          -- (Pa_OpenStream str 0 out-param *samplerate* 512 0 (ccallback pa-callback) 0)

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

