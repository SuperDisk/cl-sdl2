(in-package :sdl2-examples)

;; #+wasm
;; (progn
;;   (ffi:clines "#include <emscripten.h>")
;;   (ffi:clines "#include <stdio.h>")
;;   (ffi:clines "void somefunc(void) {puts(\"whoa\");}"))

(defun test-render-clear (renderer)
  (sdl2:set-render-draw-color renderer 0 0 0 255)
  (sdl2:render-clear renderer))

(defun test-render-hello (renderer)
  (sdl2:set-render-draw-color renderer 255 0 0 255)
  ;; H
  (sdl2:render-draw-line renderer 20 20 20 100)
  (sdl2:render-draw-line renderer 20 60 60 60)
  (sdl2:render-draw-line renderer 60 20 60 100)
  ;; E
  (sdl2:render-draw-line renderer 80 20 80 100)
  (sdl2:render-draw-line renderer 80 20 120 20)
  (sdl2:render-draw-line renderer 80 60 120 60)
  (sdl2:render-draw-line renderer 80 100 120 100)
  ;; L
  (sdl2:render-draw-line renderer 140 20 140 100)
  (sdl2:render-draw-line renderer 140 100 180 100)
  ;; L
  (sdl2:render-draw-line renderer 200 20 200 100)
  (sdl2:render-draw-line renderer 200 100 240 100)
  ;; O
  (sdl2:render-draw-line renderer 260 20 260 100)
  (sdl2:render-draw-line renderer 260 100 300 100)
  (sdl2:render-draw-line renderer 300 20 300 100)
  (sdl2:render-draw-line renderer 260 20 300 20))

(defun test-render-lines (renderer)
  (sdl2:with-points ((a 200 200)
                     (b 300 400)
                     (c 400 200))
    (sdl2:set-render-draw-color renderer 0 0 255 255)
    (multiple-value-bind (points num) (sdl2:points* a b c)
      (sdl2:render-draw-lines renderer points num))))

(defun test-render-points (renderer)
  (sdl2:with-points ((a (random 800) (random 800))
                     (b (random 800) (random 800))
                     (c (random 800) (random 800)))
    (sdl2:set-render-draw-color renderer 0 255 0 255)
    (multiple-value-bind (points num) (sdl2:points* a b c)
      (sdl2:render-draw-points renderer points num))))

(defun test-render-rect (renderer)
  (sdl2:render-draw-rect renderer (sdl2:make-rect 400 400 35 35)))

(defun test-render-rects (renderer)
  (multiple-value-bind (rects num)
      (apply #'sdl2:rects*
             (loop :for x :upto 5
                   :for y :upto 5
                   :collect (sdl2:make-rect (+ 400 (* x 10)) (+ 200 (* y 10)) 8 8)))
    (sdl2:render-draw-rects renderer rects num)))

(defun test-render-fill-rect (renderer)
  (sdl2:render-fill-rect renderer (sdl2:make-rect 445 400 35 35)))

(defun test-render-fill-rects (renderer)
  (multiple-value-bind (rects num)
      (apply #'sdl2:rects*
             (loop :for x :upto 5
                   :collect (sdl2:make-rect (+ 500 (* x 10)) 400 8 8)))
    (sdl2:set-render-draw-color renderer 255 0 255 255)
    (sdl2:render-fill-rects renderer rects num)))

(defparameter renderer2 nil)

(defun mainloop ()
  (test-render-clear renderer2)
  (test-render-hello renderer2)
  (test-render-lines renderer2)
  (test-render-points renderer2)
  (test-render-rect renderer2)
  (test-render-rects renderer2)
  (test-render-fill-rect renderer2)
  (test-render-fill-rects renderer2)
  (sdl2:render-present renderer2)
  (sdl2:pump-events)
  (sdl2:delay 33))

#+wasm
(progn
  (eval-when (:compile-toplevel :load-toplevel :execute)
    (format t "Setting up wasm callback stuff~%"))
  (cffi:defcfun "emscripten_set_main_loop" :void
    (func :pointer)
    (fps :int)
    (simulate-infinite-loop :int))

  (cffi:defcallback ems-mainloop :void ()
    (mainloop)))

(defun renderer-test ()
  "Test the SDL_render.h API"
  (sdl2:with-init* ()
    (sdl2:with-window (win :title "SDL2 Renderer API Demo" :flags '(:shown))
      (sdl2:with-renderer (renderer win :flags '(:software))
        (setf renderer2 renderer)
        #+wasm
        (emscripten-set-main-loop
         (cffi:callback ems-mainloop)
         0
         1)

        ;; #+wasm
        ;; (ffi:c-inline () () :void "emscripten_set_main_loop(somefunc, 0, 1);")

        #-wasm
        (loop (mainloop))))))
