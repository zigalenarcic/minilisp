(load "portaudio.lisp")
(load "opengl.lisp")

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

(function sound-callback (input output frameCount timeInfo statusFlags userData)
          --(print "Sound callback \n")
          --(print "frame count: " frameCount "\n")
          --(print "input " (hex input) "\n")

          (set amp-l 0.0)
          (set av (array-view-ptr 'i16 (* 2 frameCount) input))
          (loop (i 0) (< i frameCount) (+ 1 i)
                (aset audio-buffer audio-buffer-pos (aget av (* 2 i)))
                (aset audio-buffer (+ audio-buffer-pos 1) (aget av (+ (* 2 i) 1)))
                (set audio-buffer-pos (+ audio-buffer-pos 2))
                (if (>= audio-buffer-pos (* 2 1024 1024))
                  (set audio-buffer-pos 0))

                (if (> (abs (aget av (* 2 i))) amp-l) (set amp-l (abs (aget av (* 2 i)))))

                )
          --(print av)
          --(write out-file av)

          (set tmp-amp (/ amp-l 32768.0))

          (set amplitude-l (if (> tmp-amp 0.0) (/ (+ 3.0 (/ (log tmp-amp) (log 10))) 3.0) 0.0))

          paContinue
          )

(set window-width 640)
(set window-height 480)
(set should-quit n)
(set window n)

(set amplitude-l 0.0)
(set amplitude-r 0.0)

(set audio-buffer (array 'i16 (* 2 1024 1024)))
(set audio-buffer-pos 0)

(function set-viewport (window width height)
          (set window-width width)
          (set window-height height)
          (glViewport 0 0 window-width window-height)
          (glMatrixMode GL_PROJECTION)
          (glLoadIdentity)
          (glOrtho 0.0 (* 1.0 window-width) (* 1.0 window-height) 0.0 -1.0 1.0))

(function key-pressed (window key scancode action mods)
          (if (and (= key GLFW_KEY_ESCAPE) (= action GLFW_PRESS))
            (set should-quit 1))
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

(function render ()
          (glClear GL_COLOR_BUFFER_BIT)
          (glMatrixMode GL_MODELVIEW)
          (glLoadIdentity)

          --(glTranslated (* 0.5 window-width) (* 0.5 window-height) 0.0)
          --(glScaled 1.0 -1.0 1.0)

          (set x-origin (list 0.0))
          (set y-origin (list 0.0))

          (set x-max (list window-width))
          (set y-max (list window-height))

          (glColor3d 0.8 0.8 0.8)
          (draw-rectangle 50.0 50.0 100.0 100.0)

          (set widget-width 50.0)

          (push (+ (first x-origin) (- window-width widget-width)) x-origin)
          (push (+ (first y-origin) 1.0) y-origin)

          (draw-rectangle (first x-origin) (first y-origin) widget-width (- window-height 1.0))

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

          )

(function main-loop ()
          (set new-time (get-time))
          (set time-delta (- new-time time))
          --(process-input time-delta)
          --(time-step time-delta)
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

          (set in-param (array 'u8 32))

          (loop (i 0) (< i 32) (+ i 1)
                (aset in-param i 0))

          (aset in-param 4 2)
          (aset in-param 8 8)

          (Pa_OpenStream str in-param 0 44100.0 512 0 (ccallback pa-callback) 0)

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

