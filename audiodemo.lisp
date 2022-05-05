(load "portaudio.lisp")

(Pa_Initialize)

(set str (make-array 1 'u64))

(Pa_OpenDefaultStream str 0 2 paFloat32 44100.0 512 0 0)

(set stream (aget str 0))

(Pa_StartStream stream)

(set a (make-array 1024 'f32))

(loop (i 0) (< i 512) (+ i 1)
      (aset a (* i 2) (+ -1.0 (/ i 512.0 0.5)))
      (aset a (+ (* i 2) 1) (+ -1.0 (/ i 512.0 0.5))))

(loop (i 0) (< i 512) (+ i 1)
      (Pa_WriteStream stream a 512))

(Pa_Sleep 1000)

