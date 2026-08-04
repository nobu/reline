require_relative '../helper'
return unless Reline.const_defined?(:Windows)

class Reline::Windows
  class Test < Reline::TestCase
    def test_does_not_define_win32api
      refute Reline::Windows.const_defined?(:Win32API, false)
    end

    def test_empty_buffer_uses_input_pending
      windows = Reline::Windows.allocate
      input = Object.new
      input.define_singleton_method(:input_pending?) { false }
      windows.instance_variable_set(:@input, input)
      windows.instance_variable_set(:@output_buf, [])
      assert windows.empty_buffer?

      input.define_singleton_method(:input_pending?) { true }
      refute windows.empty_buffer?
    end

    def test_screen_operations_ignore_system_call_errors
      windows = Reline::Windows.allocate
      console_output = Object.new
      console_output.define_singleton_method(:method_missing) { |*| raise Errno::EIO }
      windows.instance_variable_set(:@console_output, console_output)
      windows.instance_variable_set(:@legacy_console, true)

      assert_nothing_raised(SystemCallError) do
        windows.move_cursor_column(1)
        windows.move_cursor_up(1)
        windows.move_cursor_down(1)
        windows.erase_after_cursor
        windows.clear_screen
        windows.hide_cursor
        windows.show_cursor
      end
    end

    def test_legacy_console_is_false_on_system_call_error
      windows = Reline::Windows.allocate
      console_output = Object.new
      console_output.define_singleton_method(:tty?) { |*| true }
      console_output.define_singleton_method(:console_mode) { raise Errno::EIO }
      windows.instance_variable_set(:@console_output, console_output)

      refute windows.send(:legacy_console?)
    end

    def test_disable_auto_linewrap_yields_on_system_call_error
      windows = Reline::Windows.allocate
      console_output = Object.new
      console_output.define_singleton_method(:console_mode) { raise Errno::EIO }
      windows.instance_variable_set(:@console_output, console_output)
      calls = 0

      windows.disable_auto_linewrap { calls += 1 }

      assert_equal 1, calls
    end
  end

  class KeyEventRecord::Test < Reline::TestCase

    def setup
      # Ctrl+A
      @key = Reline::Windows::KeyEventRecord.new(0x41, 1, Reline::Windows::LEFT_CTRL_PRESSED)
    end

    def test_matches__with_no_arguments_raises_error
      assert_raise(ArgumentError) { @key.match? }
    end

    def test_matches_char_code
      assert @key.match?(char_code: 0x1)
    end

    def test_matches_virtual_key_code
      assert @key.match?(virtual_key_code: 0x41)
    end

    def test_matches_control_keys
      assert @key.match?(control_keys: :CTRL)
    end

    def test_doesnt_match_alt
      refute @key.match?(control_keys: :ALT)
    end

    def test_doesnt_match_empty_control_key
      refute @key.match?(control_keys: [])
    end

    def test_matches_control_keys_and_virtual_key_code
      assert @key.match?(control_keys: :CTRL, virtual_key_code: 0x41)
    end

  end
end
