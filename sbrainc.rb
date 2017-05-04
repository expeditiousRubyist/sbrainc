#!/usr/bin/env ruby
# sbrainc
# Copyright (c) 2017 Rubyist

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# A compiler for "Semantic Brain", an extension of Brainfuck made by this guy:
# https://github.com/silverwingedseraph/sbrain
# Transpiles .sbrain source to .c source and then compiles with GCC

require 'fileutils'

PREAMBLE = <<PROGRAM
#include <stdio.h>
#include <stdlib.h>

int cells[0x10000] = {0};
int stack[0x100]   = {0};

int main(void)
{
  int sptr = 0;
  int ptr = 0;
  int aux = 0;

PROGRAM

C_FILENAME = ".sbrainmain.c".freeze

jumpstack = []
currlabel = 0
output = PREAMBLE
input  = File.read ARGV[0]

input.each_char do |c|
  case c
  when '<' then output << "  ptr++;\n"
  when '>' then output << "  ptr--;\n"
  when '-' then output << "  cells[ptr]++;\n"
  when '+' then output << "  cells[ptr]--;\n"
  when '[' then
    output << "loopbegin#{currlabel}:\n"
    output << "  if (!cells[ptr]) goto loopend#{currlabel};\n"
    jumpstack.push currlabel
    currlabel += 1
  when ']' then
    unless jumpstack.empty?
      output << "  goto #{jumpstack[-1]};\n"
      output << "loopend#{jumpstack.pop}:\n"
    end
  when '.' then output << "  putchar(cells[ptr]);\n"
  when ',' then output << "  cells[ptr] = getchar();\n"
  when '{' then output << "  stack[sptr++] = cells[ptr];\n"
  when '}' then output << "  cells[ptr] = stack[sptr--];\n"
  when '(' then output << "  aux = cells[ptr];\n"
  when ')' then output << "  cells[ptr] = aux;\n"
  when 'z' then output << "  aux = 0;\n"
  when '!' then output << "  aux = ~aux;\n"
  when 's' then output << "  aux <<= 1;\n"
  when 'S' then output << "  aux = (int)((unsigned)aux >> 1);\n"
  when '@' then output << "  exit(aux);\n"
  when '|' then output << "  cells[ptr] |= aux;\n"
  when '&' then output << "  cells[ptr] &= aux;\n"
  when '*' then output << "  cells[ptr] ^= aux;\n"
  when '^' then output << "  cells[ptr] = ~(cells[ptr] | aux);\n"
  when '$' then output << "  cells[ptr] = ~(cells[ptr] & aux);\n"
  when 'a' then output << "  cells[ptr] += aux;\n"
  when 'd' then output << "  cells[ptr] -= aux;\n"
  when 'q' then output << "  cells[ptr] /= aux;\n"
  when 'm' then output << "  cells[ptr] %= aux;\n"
  when 'p' then output << "  cells[ptr] *= aux;\n"
  end
end

raise "Unmatched [" unless jumpstack.empty?

output << "return aux;\n}\n"

tmp = File.open C_FILENAME, "w"
tmp.write output
tmp.close

`gcc -O3 #{C_FILENAME}`
FileUtils.rm C_FILENAME