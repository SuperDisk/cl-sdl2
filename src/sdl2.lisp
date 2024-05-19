(in-package #:sdl2)

(define-condition sdl-error (error)
  ((string :initarg :string :initform nil :accessor sdl-error-string))
  (:report (lambda (c s)
             (with-slots (string) c
               (format s "SDL Error: ~A" string)))))

(define-condition sdl-rc-error (sdl-error)
  ((code :initarg :rc :initform nil :accessor sdl-error-code))
  (:report (lambda (c s)
             (with-slots (code string) c
               (format s "SDL Error (~A): ~A" code string)))))

(define-condition sdl-continue (condition) ())
(define-condition sdl-quit (condition) ())

(defun sdl-true-p (integer-bool)
  "Use this function to convert truth from a low level wrapped SDL function returning an SDL_true
into CL's boolean type system."
  (= (autowrap:enum-value 'sdl2-ffi:sdl-bool :true) integer-bool))

(autowrap:define-bitmask-from-constants (sdl-init-flags)
  sdl2-ffi:+sdl-init-timer+
  sdl2-ffi:+sdl-init-audio+
  sdl2-ffi:+sdl-init-video+
  sdl2-ffi:+sdl-init-joystick+
  sdl2-ffi:+sdl-init-haptic+
  sdl2-ffi:+sdl-init-gamecontroller+
  sdl2-ffi:+sdl-init-noparachute+
  '(:everything . #x0000FFFF))

;;; NAMING CONVENTION: check-<foo>
;;; If <foo> names a specific value (true, false, zero, null, etc),
;;; check-<foo> shall error `(when <foo> ...)`.  E.g., `(check-false
;;; x)` will *error* when `x` is false.
;;; If <foo> names something that can have an error state (like a
;;; return code), `(check-<foo> x)` shall error when `x` is in that
;;; state.

(defmacro check-rc (form)
  (with-gensyms (rc)
    `(let ((,rc ,form))
       (when (minusp ,rc)
         (error 'sdl-rc-error :rc ,rc :string (sdl-get-error)))
       ,rc)))

(defmacro check-zero (form)
  (with-gensyms (rc)
    `(let ((,rc ,form))
       (when (zerop ,rc)
         (error 'sdl-rc-error :rc ,rc :string (sdl-get-error)))
       ,rc)))

(defmacro check-false (form)
  (with-gensyms (rc)
    `(let ((,rc ,form))
       (when (not (sdl-true-p ,rc))
         (error 'sdl-rc-error :rc ,rc :string (sdl-get-error)))
       ,rc)))

(defmacro check-nullptr (form)
  (with-gensyms (wrapper)
    `(let ((,wrapper ,form))
       (if (null-pointer-p (autowrap:ptr ,wrapper))
           (error 'sdl-error :string (sdl-get-error))
           ,wrapper))))

(defmacro check-nil (form)
  (with-gensyms (v)
    `(let ((,v ,form))
       (if (null ,v)
           (error 'sdl-error :string (sdl-get-error))
           ,v))))

(defun handle-message (msg)
  (let ((fun (car msg))
        (chan (cdr msg))
        (condition))
    (handler-bind ((sdl-continue
                     (lambda (c)
                       (declare (ignore c))
                       (when chan (sendmsg chan nil))
                       (return-from handle-message)))
                   (sdl-quit
                     (lambda (c)
                       (declare (ignore c))
                       (quit)
                       (return-from handle-message))))
      (handler-bind ((error (lambda (e) (setf condition e))))
        (if chan
            (sendmsg chan (multiple-value-list (funcall fun)))
            (funcall fun))))))

(defmacro without-fp-traps (&body body)
  #+sbcl
  `(sb-int:with-float-traps-masked (:underflow :overflow :inexact :invalid :divide-by-zero)
     ,@body)
  #-sbcl
  `(progn ,@body))

(defun ensure-main-channel ()
  (unless *main-thread-channel*
    (setf *main-thread-channel* (make-channel))))

(defun make-this-thread-main (&optional function)
  "Designate the current thread as the SDL2 main thread. This function will not return until
`SDL2:QUIT` is handled. Users of this function will need to start other threads before this call, or
specify `FUNCTION`.

If `FUNCTION` is specified, it will be called when the main thread channel is ensured. This is like
calling `IN-MAIN-THREAD`, except it allows for a potentially single-threaded application. This
function does **not** return just because `FUNCTION` returns; it still requires `SDL2:QUIT` be
processed.

This does **not** call `SDL2:INIT` by itself. Do this either with `FUNCTION`, or from a separate
thread."
  (ensure-main-channel)
  (when (functionp function)
    (sendmsg *main-thread-channel* (cons function nil)))
  (sdl-main-thread))

(defun init* (flags)
  "Low-level function to initialize SDL2 with the supplied subsystems. Useful
   when not using cl-sdl2's threading mechanisms."
  #+nil(sdl-init (autowrap:mask-apply 'sdl-init-flags flags)))

(defun was-init (&rest flags)
  (/= 0 (sdl-was-init (autowrap:mask-apply 'sdl-init-flags flags))))

(defun quit ()
  "Shuts down SDL2.")

(defun quit* ()
  "Low-level function to quit SDL2. Useful when not using cl-sdl2's
   threading mechanisms."
  (sdl-quit))

(defmacro with-init ((&rest sdl-init-flags) &body body)
  `(progn
     (init ,@sdl-init-flags)
     (unwind-protect
          (in-main-thread () ,@body)
       (quit))))

(defmacro with-init* ((&rest sdl-init-flags) &body body)
  `(progn
     (init* (list ,@sdl-init-flags))
     ,@body
     (unwind-protect
          (progn ,@body)
       (quit))))

(defun niy (message)
  (error "SDL2 Error: Construct Not Implemented Yet: ~A" message))

(defun version ()
  (c-let ((ver sdl2-ffi:sdl-version :free t))
    (sdl-get-version (ver &))
    (values (ver :major) (ver :minor) (ver :patch))))

(defun version-wrapped ()
  (values sdl2-ffi:+sdl-major-version+
          sdl2-ffi:+sdl-minor-version+
          sdl2-ffi:+sdl-patchlevel+))
