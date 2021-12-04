(load "portaudio.lisp")

(Pa_Initialize)

(set str (array 'u64 1))

(Pa_OpenDefaultStream str 0 2 paFloat32 44100.0 512 0 0)

(set stream (aget str 0))

(Pa_StartStream stream)

(set a (array 'f32 1024))

(loop (i 0) (< i 512) (+ i 1)
      (aset a (* i 2) (+ -1.0 (/ i 512.0 0.5)))
      (aset a (+ (* i 2) 1) (+ -1.0 (/ i 512.0 0.5))))

(loop (i 0) (< i 512) (+ i 1)
      (Pa_WriteStream stream a 512))

(Pa_Sleep 1000)

