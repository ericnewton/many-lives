#! /bin/bash
if ! swift --version >/dev/null 2>&1 ; then
    echo you must install swift
    exit 1
fi
swift -O life.swift
