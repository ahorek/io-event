# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

return unless IO.const_defined?(:Buffer)

require 'io/event'
require 'io/event/selector'
require 'socket'

BufferedIO = Sus::Shared("buffered io") do
	with 'a pipe' do
		let(:pipe) {IO.pipe}
		let(:input) {pipe.first}
		let(:output) {pipe.last}
		
		it "can read using a buffer" do
			writer = Fiber.new do
				buffer = IO::Buffer.new(128)
				expect(selector.io_write(Fiber.current, output, buffer, 128)).to be == 128
			end
			
			reader = Fiber.new do
				buffer = IO::Buffer.new(64)
				expect(selector.io_read(Fiber.current, input, buffer, 1)).to be == 64
			end
			
			reader.transfer
			writer.transfer
			
			expect(selector.select(1)).to be == 1
		end
	end
end

IO::Event::Selector.constants.each do |name|
	klass = IO::Event::Selector.const_get(name)
	
	next unless klass.instance_methods.include?(:io_read)
	
	describe(klass, unique: name) do
		def before
			@loop = Fiber.current
			@selector = subject.new(@loop)
		end
		
		def after
			@selector&.close
		end
		
		attr :loop
		attr :selector
		
		it_behaves_like BufferedIO
	end
end