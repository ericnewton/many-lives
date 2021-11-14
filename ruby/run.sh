#! /bin/bash
ruby --version >/dev/null || echo you must intall ruby
ruby --jit --jit-wait --jit-min-calls=100 life.rb
