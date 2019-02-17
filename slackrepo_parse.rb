#!/usr/bin/env ruby
#
# The MIT License (MIT)
#
# Copyright (c) 2017 Andrew Clemons, Wellington New Zealand
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'time'

START           = 0
PACKAGE_HEADER  = 1
PACKAGE_BODY    = 2
FOOTER_HEADER   = 3
FOOTER_BODY     = 4
FOOTER_WARNINGS = 5
DONE            = 6

def start_junit_testcase(slackrepo_package, xml)
  directory, package = slackrepo_package.split(%r{/})

  xml.write("  <testcase classname='#{directory}' name='#{package}' file='#{directory}/#{package}.SlackBuild'>\n")
end

def write_junit_testcase_body(xml, tag, data)
  xml.write("    <#{tag}><![CDATA[#{data}]]></#{tag}>\n")
end

def end_junit_testcase(xml)
  xml.write("  </testcase>\n")
end

testsuite_name, checkstyle_file, junit_file, input_file = ARGV

begin
  checkstyle = File.open(checkstyle_file, 'w')
  checkstyle.write("<?xml version='1.0'?>\n")
  checkstyle.write("<checkstyle>\n")

  junit = File.open(junit_file, 'w')
  junit.write("<?xml version='1.0'?>\n")
  junit.write("<testsuite name='#{testsuite_name}' tests='TEST_COUNT' skipped='SKIPPED' failures='FAILURES' errors='0' timestamp='#{Time.now.utc.iso8601}'>\n")

  success_count = 0
  failure_count = 0
  skipped_count = 0

  state = START
  package_name = nil
  package_body = ''
  result = ''

  File.foreach(input_file) do |line|
    case state
    when START
      state = PACKAGE_HEADER if line =~ /={80}/
    when PACKAGE_HEADER
      if line =~ /={80}/
        state = PACKAGE_BODY
      else
        package_name = /^([^\s]+)\s+.*$/.match(line).captures[0]

        state = FOOTER_HEADER if package_name == 'SUMMARY'
      end
    when PACKAGE_BODY
      if line =~ /={80}/
        state = PACKAGE_HEADER

        if result =~ /^:-\)/
          success_count += 1

          start_junit_testcase(package_name, junit)
        elsif result =~ %r{^:-/}
          skipped_count += 1

          start_junit_testcase(package_name, junit)
          junit.write("    <skipped />\n")
          write_junit_testcase_body(junit, 'system-out', package_body)
        elsif result =~ /^:-\(/ || result =~ /^Missing dependency:/ || result =~ /^ERROR:/
          failure_count += 1

          start_junit_testcase(package_name, junit)
          write_junit_testcase_body(junit, 'failure', package_body)
        else
          success_count += 1

          start_junit_testcase(package_name, junit)
          write_junit_testcase_body(junit, 'system-out', package_body)
        end

        end_junit_testcase(junit)

        package_body = ''
        result = ''
      elsif line =~ /^:-/ || line =~ /^Missing dependency:/ || line =~ /^ERROR:/
        result = line
      else
        package_body += line
      end
    when FOOTER_HEADER
      state = FOOTER_BODY if line =~ /={80}/
    when FOOTER_BODY
      state = FOOTER_WARNINGS if line =~ /^Warnings/
    when FOOTER_WARNINGS
      if line =~ /^$/
        state = DONE
      elsif line =~ /Packages with tag .* are already installed$/
        # ignored
      else
        package, warning = /^\s*(.*?): (.*)$/.match(line).captures
        directory, package_name = package.split(%r{/})

        checkstyle.write("<file name='#{directory}/#{package_name}.SlackBuild'>\n")
        checkstyle.write("  <error severity='info' message='#{warning}'/>\n")
        checkstyle.write("</file>\n")
      end
    end
  end
ensure
  unless checkstyle.nil?
    checkstyle.write("</checkstyle>\n")
    checkstyle.close
  end

  unless junit.nil?
    junit.write("</testsuite>\n")
    junit.close

    `sed -i '2 s/TEST_COUNT/#{success_count + failure_count + skipped_count}/' #{junit_file}`
    `sed -i '2 s/SKIPPED/#{skipped_count}/' #{junit_file}`
    `sed -i '2 s/FAILURES/#{failure_count}/' #{junit_file}`
  end
end
