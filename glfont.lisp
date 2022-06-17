
(const *gl-font* '(n n n n n n n n
                   n n n n n n n n
                   n n n n n n n n
                   n n n n n n n n

                   -- 0
                   ((0 1) (1 0) (2 1) (2 3) (1 4) (0 3) (0 1) (-1 -1) (0 3) (2 1))
                   -- 1
                   ((0 1) (1 0) (1 4))
                   -- 2
                   ((0 1) (1 0) (2 1) (0 4) (2 4))
                   -- 3
                   ((0 1) (1 0) (2 1) (1 2) (2 3) (1 4) (0 3))
                   -- 4
                   ((1 0) (0 3) (2 3) (-1 -1) (1 2) (1 4))
                   -- 5
                   ((2 0) (0 0) (0 2) (1 1) (2 2) (2 3) (1 4) (0 3))
                   -- 6
                   ((2 1) (1 0) (0 1) (0 3) (1 4) (2 3) (1 2) (0 3))
                   -- 7
                   ((0 0) (2 0) (0 4) (-1 -1) (0 2) (2 2))
                   -- 8
                   ((1 0) (2 1) (0 3) (1 4) (2 3) (0 1) (1 0))
                   -- 9
                   ((2 1) (1 2) (0 1) (1 0) (2 1) (2 3) (1 4) (0 3))

                   -- A
                   ((0 4) (0 2) (1 0) (2 2) (2 4) (-1 -1) (0 2) (2 2))





                   ))

(function gl-draw-letter (l)
          (glBegin GL_LINE_STRIP)
          (loop-list (e (nth *gl-font* l))
                   (set x (first e))
                   (set y (first (rest e)))

                   (if (= x -1)
                     (do
                       (glEnd)
                       (glBegin GL_LINE_STRIP))
                     (glVertex2i x y))

                   )
          (glEnd))

(function gl-draw-string (s)
          (glPushMatrix)
          (set l (length s))
          (loop (i 0) (< i l) (+ 1 i)
                (gl-draw-letter (aget s i))
                (glTranslatef 4.0 0.0 0.0)
                )
          (glPopMatrix))
