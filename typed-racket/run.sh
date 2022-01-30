#! /bin/bash
racket --version >/dev/null || echo you must install racket
racket -I typed/racket typed-life.rkt
