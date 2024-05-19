(cl:in-package :sdl2-ffi)

(cl:format cl:t "DEFINING AUTOWRAP STUFF~%")

(autowrap:c-include
 "spec/SDL2.h"
 ;; '(sdl2 autowrap-spec "SDL2.h")
 :accessor-package :sdl2-ffi.accessors
 :function-package :sdl2-ffi.functions
 :spec-path "spec/" ;'(sdl2 autowrap-spec)
 :exclude-sources ("/usr/local/lib/clang/([^/]*)/include/(?!stddef.h)"
                   "/usr/include/"
                   "/home/npfaro/Desktop/ecl-wasm/emsdk/upstream/emscripten/cache/sysroot/include/"
                   "/usr/include/arm-linux-gnueabihf"
                   "/usr/include/X11/")
 :include-sources ("stdint.h"
                   "bits/types.h"
                   "sys/types.h"
                   "bits/stdint"
                   "bits/alltypes"
                   "machine/_types.h"
                   "SDL2")
 :sysincludes `,(cl:append
                 #+openbsd (cl:list "/usr/X11R6/include")
                 #+(and unix (not darwin))
                 (cl:list "/usr/lib/clang/13.0.1/include/"))
 :exclude-definitions ("SDL_main"
                       "SDL_LogMessageV"
                       "SDL_vsnprintf"
                       "_inline$"
                       "^_mm_"
                       "__tile1024i_str"
                       "__tile1024i"
                       "__tile_loadd"
                       "__tile_stream_loadd"
                       "__tile_dpbssd"
                       "__tile_dpbsud"
                       "__tile_dpbusd"
                       "__tile_dpbuud"
                       "__tile_stored"
                       "__tile_zero"
                       "__tile_dpbf16ps"
                       "pthread_attr_t"
                       "pthread_mutex_t"
                       "pthread_cond_t"
                       "pthread_rwlock_t"
                       "pthread_barrier_t"
                       "__pthread"
                       "pthread_t"
                       "pthread_once_t"
                       "pthread_key_t"
                       "pthread_spinlock_t"
                       "pthread_mutexattr_t"
                       "pthread_condattr_t"
                       "pthread_barrierattr_t"
                       "pthread_rwlockattr_t"
                       "calloc"
                       "realloc"
                       "memcpy"
                       "malloc"
                       "memset")
 :include-definitions ("^XID$" "^Window$" "^Display$" "^_XDisplay$")
 :symbol-exceptions (("SDL_Log" . "SDL-LOGGER")
                     ("SDL_log" . "SDL-LOGN")
                     ("SDL_RWops" . "SDL-RWOPS")
                     ("SDL_GLContext" . "SDL-GLCONTEXT")
                     ("SDL_GLattr" . "SDL-GLATTR")
                     ("SDL_GLprofile" . "SDL-GLPROFILE")
                     ("SDL_GLcontextFlag" . "SDL-GLCONTEXT-FLAG")
                     ("SDL_SysWMinfo" . "SDL-SYSWM-INFO")
                     ("SDL_SysWMmsg" . "SDL-SYSWM-MSG")
                     ("SDL_TRUE" . "TRUE")
                     ("SDL_FALSE" . "FALSE"))
 :no-accessors cl:t)

(cl:format cl:t "DONE DEFINING AUTOWRAP STUFF: ~a~%"
           (cl:loop for key being each hash-key of autowrap::*wrapper-constructors* collect key))
